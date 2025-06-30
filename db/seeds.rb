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
company = Company.find_or_create_by!(name: 'SR Next', email: 'info@srnext.in', phone_number: '1234567890', address: 'Cabin 10', status: 'active')

# Seed Workspaces
workspace = Workspace.find_or_create_by!(name: 'Floor 5', building_name: 'Nextcoworks', address: 'Slice 6 Aranya Nagar Vijay Nagar', city: 'Indore', pincode: '452010', photo: nil, is_active: true)

# Associate Company and Workspace
CompanyWorkspace.find_or_create_by!(company: company, workspace: workspace)

# Seed Users
user = User.find_or_create_by!(email: 'floor_user@gmail.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.role = 'floor_user'
  u.name = 'Floor User'
end

# Associate User and Company
CompanyUser.find_or_create_by!(company: company, user: user)

# Associate User and Workspace
UserWorkspace.find_or_create_by!(user: user, workspace: workspace)

# Seed Rooms
tesla_room = Room.find_or_create_by!(name: 'Tesla', category: 'Conference', workspace_id: workspace.id, capacity: 20, whiteboard: true, projector: true, is_available: true)
mercedes_room = Room.find_or_create_by!(name: 'Mercedes', category: 'Conference', workspace_id: workspace.id, capacity: 20, whiteboard: true, projector: true, is_available: true)
alto_room = Room.find_or_create_by!(name: 'Alto', category: 'Meeting', workspace_id: workspace.id, capacity: 6, whiteboard: true, projector: true, is_available: true)
nano_room = Room.find_or_create_by!(name: 'Nano', category: 'Meeting', workspace_id: workspace.id, capacity: 6, whiteboard: true, projector: true, is_available: true)

# Associate Company with all Rooms
CompanyRoom.find_or_create_by!(company: company, room: tesla_room)
CompanyRoom.find_or_create_by!(company: company, room: nano_room)