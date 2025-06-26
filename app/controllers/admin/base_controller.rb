class Admin::BaseController < ApplicationController
  layout 'admin'
  # Temporarily commented out for UI testing
  before_action :authenticate_user!
  before_action :require_admin!

  private

  def require_admin!
    redirect_to root_path unless current_user.admin? || current_user.super_admin?
  end
  
end