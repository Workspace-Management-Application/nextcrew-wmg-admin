# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed Companies
company = Company.find_or_create_by!(name: 'Acme Corp', email: 'info@acme.com', phone_number: '1234567880', address: '123 Main St', status: 'active')

# Seed Workspaces
workspace = Workspace.find_or_create_by!(name: 'Downtown Workspace', building_name: 'Downtown Tower', address: '456 Center Ave', city: 'Metropolis', pincode: '123456', photo: nil, is_active: true)

# Associate Company and Workspace
CompanyWorkspace.find_or_create_by!(company: company, workspace: workspace)

# Seed Users
user = User.find_or_create_by!(email: 'admin@acme.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.role = 'admin'
  u.name = 'Admin User'
end

# Associate User and Company
CompanyUser.find_or_create_by!(company: company, user: user)

# Associate User and Workspace
UserWorkspace.find_or_create_by!(user: user, workspace: workspace)

# Seed Rooms
room = Room.find_or_create_by!(name: 'Conference Room A', category: 'Conference', workspace_id: workspace.id, capacity: 10, whiteboard: true, projector: true, is_available: true)

# Optionally, seed a booking
Booking.find_or_create_by!(booker_name: user.name, phone_number: '1234567890', user: user, room: room, start_time: Time.now + 1.day, end_time: Time.now + 1.day + 2.hours, status: 'confirmed')
