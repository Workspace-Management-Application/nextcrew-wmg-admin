#!/bin/bash

# Rails Application Deployment Script
# Usage: ./deploy.sh [branch_name]
# Default branch: main

set -e  # Exit on any error

# Configuration
APP_DIR="/home/ec2-user/workspace-management-rails"
RAILS_ENV="production"
BRANCH="${1:-main}"
BACKUP_DIR="/home/ec2-user/backups"
LOG_FILE="$APP_DIR/log/deploy.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')] INFO:${NC} $1" | tee -a "$LOG_FILE"
}

# Check if script is run as ec2-user
check_user() {
    if [ "$USER" != "ec2-user" ]; then
        error "This script must be run as ec2-user"
        exit 1
    fi
}

# Setup RVM environment
setup_rvm() {
    log "Setting up RVM environment..."
    source /home/ec2-user/.rvm/scripts/rvm
    rvm use 3.3.4
    if [ $? -ne 0 ]; then
        error "Failed to setup RVM environment"
        exit 1
    fi
}

# Create backup directory
create_backup_dir() {
    log "Creating backup directory..."
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$APP_DIR/log"
}

# Backup current application
backup_app() {
    log "Creating backup of current application..."
    BACKUP_NAME="backup_$(date +%Y%m%d_%H%M%S)"
    if [ -d "$APP_DIR" ]; then
        cp -r "$APP_DIR" "$BACKUP_DIR/$BACKUP_NAME"
        log "Backup created: $BACKUP_DIR/$BACKUP_NAME"
    else
        warning "Application directory not found, skipping backup"
    fi
}

# Check if services are running
check_services() {
    log "Checking service status..."
    if ! systemctl is-active --quiet nginx; then
        warning "Nginx is not running"
    else
        info "Nginx is running ✓"
    fi
    
    if ! systemctl is-active --quiet puma; then
        warning "Puma is not running"
    else
        info "Puma is running ✓"
    fi
}

# Git operations
git_operations() {
    log "Performing git operations..."
    cd "$APP_DIR"
    
    # Stash any local changes
    STASH_RESULT=$(git stash save "Auto-stash before deploy $(date)")
    STASH_CREATED=false
    
    if [[ "$STASH_RESULT" != "No local changes to save" ]]; then
        STASH_CREATED=true
        log "Local changes stashed"
    else
        info "No local changes to stash"
    fi
    
    # Fetch latest changes
    git fetch origin
    
    # Checkout and pull the specified branch
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
    
    # Pop stash if we created one
    if [ "$STASH_CREATED" = true ]; then
        log "Restoring stashed local changes..."
        git stash pop
        if [ $? -eq 0 ]; then
            log "Stashed changes restored successfully"
        else
            warning "Failed to restore stashed changes - there might be conflicts"
        fi
    fi
    
    log "Successfully updated to branch '$BRANCH'"
    
    # Show latest commit
    LATEST_COMMIT=$(git log -1 --oneline)
    info "Latest commit: $LATEST_COMMIT"
}

# Install/update gems
bundle_install() {
    log "Installing/updating gems..."
    cd "$APP_DIR"
    
    # Check if Gemfile or Gemfile.lock has changed
    if git diff HEAD~1 --name-only | grep -q -E "(Gemfile|Gemfile.lock)"; then
        log "Gemfile or Gemfile.lock changed, running bundle install..."
        
        # Clean up bundle config first
        bundle config unset deployment 2>/dev/null || true
        bundle config unset without 2>/dev/null || true
        
        # Remove vendor/bundle if it exists to start fresh
        if [ -d "$APP_DIR/vendor/bundle" ]; then
            log "Cleaning existing bundle directory..."
            rm -rf "$APP_DIR/vendor/bundle"
        fi
        
        # Set bundle config for production deployment
        bundle config set --local deployment true
        bundle config set --local without 'development test'
        bundle config set --local path 'vendor/bundle'
        
        # Install gems with verbose output
        log "Running bundle install with verbose output..."
        bundle install --verbose
        
        if [ $? -ne 0 ]; then
            error "Bundle install failed. You may need to update Gemfile.lock locally and commit it."
            return 1
        fi
        
        # Verify the gem was installed
        if bundle list | grep -q "rack-cors"; then
            log "rack-cors gem successfully installed ✓"
        else
            error "rack-cors gem not found after bundle install"
            return 1
        fi
    else
        info "No Gemfile changes detected, but checking if bundle is properly installed..."
        
        # Even if no changes, ensure bundle is properly set up
        bundle check
        if [ $? -ne 0 ]; then
            log "Bundle check failed, running bundle install..."
            bundle install
        fi
    fi
}

# Database operations
database_operations() {
    log "Running database operations..."
    cd "$APP_DIR"
    
    # Check if there are pending migrations
    if RAILS_ENV=production bundle exec rails db:migrate:status | grep -q "down"; then
        log "Running database migrations..."
        RAILS_ENV=production bundle exec rails db:migrate
    else
        info "No pending migrations"
    fi
    
    # Optional: Load seeds if needed (uncomment if required)
    # RAILS_ENV=production bundle exec rails db:seed
}

# Precompile assets
precompile_assets() {
    log "Precompiling assets..."
    cd "$APP_DIR"
    
    # Check if asset files have changed
    if git diff HEAD~1 --name-only | grep -E "(app/assets|app/javascript|Gemfile)" > /dev/null; then
        log "Asset-related files changed, clearing and precompiling assets..."
        
        # Clear all compiled assets first
        log "Clearing existing compiled assets..."
        RAILS_ENV=production bundle exec rails assets:clobber
        
        # Precompile assets
        log "Precompiling assets..."
        RAILS_ENV=production bundle exec rails assets:precompile
    else
        info "No asset changes detected, skipping precompilation"
    fi
}

# Restart services
restart_services() {
    log "Restarting services..."
    
    # Stop services first
    sudo systemctl stop puma
    sudo systemctl stop nginx
    
    # Clean up old socket file if it exists
    sudo rm -f /home/ec2-user/workspace-management-rails/tmp/sockets/puma.sock
    
    # Ensure socket directory exists with proper permissions
    sudo mkdir -p /home/ec2-user/workspace-management-rails/tmp/sockets
    sudo chown ec2-user:ec2-user /home/ec2-user/workspace-management-rails/tmp/sockets
    sudo chmod 755 /home/ec2-user/workspace-management-rails/tmp/sockets
    
    # Ensure log directory exists
    sudo mkdir -p /home/ec2-user/workspace-management-rails/log
    sudo chown ec2-user:ec2-user /home/ec2-user/workspace-management-rails/log
    
    # Start Puma
    sudo systemctl start puma
    if [ $? -eq 0 ]; then
        log "Puma started successfully ✓"
    else
        error "Failed to start Puma"
        sudo journalctl -u puma --no-pager -n 20
        exit 1
    fi
    
    # Start Nginx
    sudo systemctl start nginx
    if [ $? -eq 0 ]; then
        log "Nginx started successfully ✓"
    else
        error "Failed to start Nginx"
        exit 1
    fi
}

# Health check
health_check() {
    log "Performing health check..."
    
    # Wait a moment for services to start
    log "Waiting 10 seconds for services to fully start..."
    sleep 10
    
    # Check service status first
    log "Checking service status..."
    PUMA_STATUS=$(systemctl is-active puma)
    NGINX_STATUS=$(systemctl is-active nginx)
    
    info "Puma status: $PUMA_STATUS"
    info "Nginx status: $NGINX_STATUS"
    
    if [ "$PUMA_STATUS" != "active" ]; then
        error "Puma service is not active"
        sudo systemctl status puma --no-pager
        return 1
    fi
    
    if [ "$NGINX_STATUS" != "active" ]; then
        error "Nginx service is not active"
        sudo systemctl status nginx --no-pager
        return 1
    fi
    
    # Check if puma socket exists
    if [ ! -S "/home/ec2-user/workspace-management-rails/tmp/sockets/puma.sock" ]; then
        error "Puma socket file does not exist"
        ls -la "/home/ec2-user/workspace-management-rails/tmp/sockets/"
        return 1
    else
        info "Puma socket file exists ✓"
    fi
    
    # Check if application responds
    log "Testing application response..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L https://nextcrew.in)
    info "HTTP response code: $HTTP_CODE"
    
    if echo "$HTTP_CODE" | grep -q "302\|200"; then
        log "Health check passed ✓"
        return 0
    else
        error "Health check failed - HTTP code: $HTTP_CODE"
        
        # Additional debugging
        log "Checking nginx error logs..."
        sudo tail -10 /var/log/nginx/rails_app_error.log
        
        log "Checking puma logs..."
        sudo journalctl -u puma --no-pager -n 10
        
        return 1
    fi
}

# Rollback function
rollback() {
    error "Deployment failed, initiating rollback..."
    
    # Find latest backup
    LATEST_BACKUP=$(ls -1t "$BACKUP_DIR" | head -n 1)
    
    if [ -n "$LATEST_BACKUP" ]; then
        log "Rolling back to: $LATEST_BACKUP"
        
        # Stop services
        sudo systemctl stop puma
        
        # Restore backup
        rm -rf "$APP_DIR"
        cp -r "$BACKUP_DIR/$LATEST_BACKUP" "$APP_DIR"
        
        # Restart services
        sudo systemctl start puma
        sudo systemctl reload nginx
        
        log "Rollback completed"
    else
        error "No backup found for rollback"
    fi
}

# Cleanup old backups (keep last 5)
cleanup_backups() {
    log "Cleaning up old backups..."
    cd "$BACKUP_DIR"
    ls -1t | tail -n +6 | xargs -r rm -rf
    log "Cleanup completed"
}

# Main deployment function
deploy() {
    log "Starting deployment of branch '$BRANCH'..."
    
    check_user
    setup_rvm
    create_backup_dir
    check_services
    backup_app
    
    # Deployment steps
    if git_operations && bundle_install && database_operations && precompile_assets && restart_services; then
        if health_check; then
            log "🎉 Deployment completed successfully!"
            cleanup_backups
            
            # Show deployment summary
            echo ""
            echo "=================================="
            echo "   DEPLOYMENT SUMMARY"
            echo "=================================="
            echo "Branch: $BRANCH"
            echo "Commit: $(cd $APP_DIR && git log -1 --oneline)"
            echo "Time: $(date)"
            echo "Services: ✓ Running"
            echo "=================================="
        else
            rollback
            exit 1
        fi
    else
        rollback
        exit 1
    fi
}

# Show usage
usage() {
    echo "Usage: $0 [branch_name]"
    echo "  branch_name: Git branch to deploy (default: main)"
    echo ""
    echo "Examples:"
    echo "  $0              # Deploy main branch"
    echo "  $0 develop      # Deploy develop branch"
    echo "  $0 feature/xyz  # Deploy feature branch"
}

# Script entry point
case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    *)
        deploy
        ;;
esac 