# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting database seeding..."

# Clear existing data in development (optional - uncomment if needed)
# if Rails.env.development?
#   puts "🗑️ Clearing existing data..."
#   [Booking, CompanyRoom, UserWorkspace, CompanyUser, CompanyWorkspace, 
#    VisitorEntry, OfficeEnquiry, DayPass, Room, User, Company, Workspace].each(&:destroy_all)
# end

# 1. Create Companies with different statuses
puts "🏢 Creating companies..."
companies = [
  {
    name: 'SR Next Technologies',
    email: 'contact@srnext.in',
    phone_number: '+91-9876543210',
    address: 'Cabin 10, Tech Park, Vijay Nagar',
    status: 'active'
  },
  {
    name: 'InnovateCorp',
    email: 'hello@innovatecorp.com',
    phone_number: '+91-9876543211',
    address: 'Floor 3, Innovation Hub, Sapna Sangeeta',
    status: 'active'
  },
  {
    name: 'StartupXYZ',
    email: 'team@startupxyz.in',
    phone_number: '+91-9876543212',
    address: 'Coworking Space, AB Road',
    status: 'pending'
  },
  {
    name: 'TechSolutions Ltd',
    email: 'info@techsolutions.co.in',
    phone_number: '+91-9876543213',
    address: 'Office Complex, Ring Road',
    status: 'approved'
  },
  {
    name: 'Inactive Company',
    email: 'old@inactive.com',
    phone_number: '+91-9876543214',
    address: 'Old Building, Scheme 54',
    status: 'inactive'
  }
]

company_records = companies.map do |company_data|
  Company.find_or_create_by!(email: company_data[:email]) do |company|
    company.assign_attributes(company_data)
  end
end

# 2. Create Workspaces
puts "🏠 Creating workspaces..."
workspaces = [
  {
    name: 'Floor 5 - Premium',
    building_name: 'Nextcoworks Central',
    address: 'Slice 6 Aranya Nagar Vijay Nagar',
    city: 'Indore',
    pincode: '452010',
    photo: nil,
    is_active: true
  },
  {
    name: 'Floor 3 - Standard',
    building_name: 'Nextcoworks Central',
    address: 'Slice 6 Aranya Nagar Vijay Nagar',
    city: 'Indore',
    pincode: '452010',
    photo: nil,
    is_active: true
  },
  {
    name: 'Ground Floor - Basic',
    building_name: 'Business Hub',
    address: 'AB Road, Sapna Sangeeta',
    city: 'Indore',
    pincode: '452001',
    photo: nil,
    is_active: true
  },
  {
    name: 'Floor 2 - Executive',
    building_name: 'Corporate Tower',
    address: 'Ring Road, Scheme 54',
    city: 'Indore',
    pincode: '452020',
    photo: nil,
    is_active: false
  }
]

workspace_records = workspaces.map do |workspace_data|
  Workspace.find_or_create_by!(name: workspace_data[:name], building_name: workspace_data[:building_name]) do |workspace|
    workspace.assign_attributes(workspace_data)
  end
end

# 3. Create Company-Workspace associations
puts "🔗 Creating company-workspace associations..."
company_workspace_associations = [
  { company: company_records[0], workspace: workspace_records[0] },
  { company: company_records[0], workspace: workspace_records[1] },
  { company: company_records[1], workspace: workspace_records[0] },
  { company: company_records[1], workspace: workspace_records[2] },
  { company: company_records[2], workspace: workspace_records[2] },
  { company: company_records[3], workspace: workspace_records[3] }
]

company_workspace_associations.each do |assoc|
  CompanyWorkspace.find_or_create_by!(company: assoc[:company], workspace: assoc[:workspace])
end

# 4. Create Users with all roles and password "123456789"
puts "👥 Creating users with all roles..."
users_data = [
  # Super Admin
  {
    email: 'superadmin@workspace.com',
    password: '123456789',
    password_confirmation: '123456789',
    name: 'Super Administrator',
    phone_number: '+91-9000000001',
    role: 'super_admin'
  },
  # Admins
  {
    email: 'admin@srnext.in',
    password: '123456789',
    password_confirmation: '123456789',
    name: 'John Admin',
    phone_number: '+91-9000000002',
    role: 'admin'
  },
  {
    email: 'admin2@innovatecorp.com',
    password: '123456789',
    password_confirmation: '123456789',
    name: 'Sarah Admin',
    phone_number: '+91-9000000003',
    role: 'admin'
  },
  # Floor Users
  {
    email: 'floor_user@gmail.com',
    password: '123456789',
    password_confirmation: '123456789',
    name: 'Floor Manager One',
    phone_number: '+91-9000000004',
    role: 'floor_user'
  },
  {
    email: 'floor_user2@workspace.com',
    password: '123456789',
    password_confirmation: '123456789',
    name: 'Floor Manager Two',
    phone_number: '+91-9000000005',
    role: 'floor_user'
  },
  {
    email: 'floor_user3@workspace.com',
    password: '123456789',
    password_confirmation: '123456789',
    name: 'Floor Manager Three',
    phone_number: '+91-9000000006',
    role: 'floor_user'
  },
  # Regular Users
  {
    email: 'user1@srnext.in',
    password: '123456789',
    password_confirmation: '123456789',
    name: 'Alice Employee',
    phone_number: '+91-9000000007',
    role: 'user'
  },
  {
    email: 'user2@innovatecorp.com',
    password: '123456789',
    password_confirmation: '123456789',
    name: 'Bob Developer',
    phone_number: '+91-9000000008',
    role: 'user'
  },
  {
    email: 'user3@startupxyz.in',
    password: '123456789',
    password_confirmation: '123456789',
    name: 'Charlie Designer',
    phone_number: '+91-9000000009',
    role: 'user'
  },
  {
    email: 'user4@techsolutions.co.in',
    password: '123456789',
    password_confirmation: '123456789',
    name: 'Diana Manager',
    phone_number: '+91-9000000010',
    role: 'user'
  }
]

user_records = users_data.map do |user_data|
  User.find_or_create_by!(email: user_data[:email]) do |user|
    user.assign_attributes(user_data)
    user.confirmed_at = Time.current # Auto-confirm users
  end
end

# 5. Create Company-User associations
puts "👤 Creating company-user associations..."
company_user_associations = [
  { company: company_records[0], user: user_records[1] }, # admin@srnext
  { company: company_records[0], user: user_records[3] }, # floor_user@gmail
  { company: company_records[0], user: user_records[6] }, # user1@srnext
  { company: company_records[1], user: user_records[2] }, # admin2@innovatecorp
  { company: company_records[1], user: user_records[4] }, # floor_user2
  { company: company_records[1], user: user_records[7] }, # user2@innovatecorp
  { company: company_records[2], user: user_records[5] }, # floor_user3
  { company: company_records[2], user: user_records[8] }, # user3@startupxyz
  { company: company_records[3], user: user_records[9] }  # user4@techsolutions
]

company_user_associations.each do |assoc|
  CompanyUser.find_or_create_by!(company: assoc[:company], user: assoc[:user])
end

# 6. Create User-Workspace associations
puts "🏢 Creating user-workspace associations..."
user_workspace_associations = [
  { user: user_records[3], workspace: workspace_records[0] }, # floor_user -> Floor 5
  { user: user_records[4], workspace: workspace_records[1] }, # floor_user2 -> Floor 3
  { user: user_records[5], workspace: workspace_records[2] }, # floor_user3 -> Ground Floor
  { user: user_records[6], workspace: workspace_records[0] }, # user1 -> Floor 5
  { user: user_records[7], workspace: workspace_records[0] }, # user2 -> Floor 5
  { user: user_records[8], workspace: workspace_records[2] }, # user3 -> Ground Floor
  { user: user_records[9], workspace: workspace_records[3] }  # user4 -> Floor 2
]

user_workspace_associations.each do |assoc|
  UserWorkspace.find_or_create_by!(user: assoc[:user], workspace: assoc[:workspace])
end

# 7. Create Rooms with different categories
puts "🏛️ Creating rooms..."
rooms_data = [
  # Floor 5 Premium rooms
  { name: 'Tesla', category: 'Conference', workspace: workspace_records[0], capacity: 20, whiteboard: true, projector: true, is_available: true },
  { name: 'Mercedes', category: 'Conference', workspace: workspace_records[0], capacity: 20, whiteboard: true, projector: true, is_available: true },
  { name: 'BMW', category: 'Conference', workspace: workspace_records[0], capacity: 15, whiteboard: true, projector: true, is_available: true },
  { name: 'Alto', category: 'Meeting', workspace: workspace_records[0], capacity: 6, whiteboard: true, projector: false, is_available: true },
  { name: 'Nano', category: 'Meeting', workspace: workspace_records[0], capacity: 4, whiteboard: true, projector: false, is_available: true },
  { name: 'Swift', category: 'Meeting', workspace: workspace_records[0], capacity: 8, whiteboard: true, projector: true, is_available: false },
  
  # Floor 3 Standard rooms
  { name: 'Boardroom Alpha', category: 'Conference', workspace: workspace_records[1], capacity: 12, whiteboard: true, projector: true, is_available: true },
  { name: 'Meeting Beta', category: 'Meeting', workspace: workspace_records[1], capacity: 6, whiteboard: true, projector: false, is_available: true },
  { name: 'Discussion Gamma', category: 'Meeting', workspace: workspace_records[1], capacity: 4, whiteboard: false, projector: false, is_available: true },
  { name: 'Presentation Delta', category: 'Presentation', workspace: workspace_records[1], capacity: 25, whiteboard: true, projector: true, is_available: true },
  
  # Ground Floor Basic rooms
  { name: 'Conference One', category: 'Conference', workspace: workspace_records[2], capacity: 10, whiteboard: true, projector: false, is_available: true },
  { name: 'Meeting Two', category: 'Meeting', workspace: workspace_records[2], capacity: 6, whiteboard: false, projector: false, is_available: true },
  { name: 'Training Room', category: 'Training', workspace: workspace_records[2], capacity: 20, whiteboard: true, projector: true, is_available: true },
  
  # Floor 2 Executive rooms (inactive workspace)
  { name: 'Executive Suite', category: 'Conference', workspace: workspace_records[3], capacity: 8, whiteboard: true, projector: true, is_available: false }
]

room_records = rooms_data.map do |room_data|
  Room.find_or_create_by!(name: room_data[:name], workspace: room_data[:workspace]) do |room|
    room.assign_attributes(room_data.except(:workspace))
  end
end

# 8. Create Company-Room associations
puts "🏛️ Creating company-room associations..."
company_room_associations = [
  { company: company_records[0], room: room_records[0] }, # SR Next -> Tesla
  { company: company_records[0], room: room_records[1] }, # SR Next -> Mercedes
  { company: company_records[0], room: room_records[3] }, # SR Next -> Alto
  { company: company_records[1], room: room_records[2] }, # InnovateCorp -> BMW
  { company: company_records[1], room: room_records[6] }, # InnovateCorp -> Boardroom Alpha
  { company: company_records[2], room: room_records[10] }, # StartupXYZ -> Conference One
  { company: company_records[3], room: room_records[13] }  # TechSolutions -> Executive Suite
]

company_room_associations.each do |assoc|
  CompanyRoom.find_or_create_by!(company: assoc[:company], room: assoc[:room])
end

# 9. Create Bookings with different statuses
puts "📅 Creating bookings..."
bookings_data = [
  {
    phone_number: '+91-9000000007',
    user: user_records[6], # Alice Employee
    room: room_records[0], # Tesla
    start_time: 2.hours.from_now,
    end_time: 4.hours.from_now,
    status: 'confirmed'
  },
  {
    phone_number: '+91-9000000008',
    user: user_records[7], # Bob Developer
    room: room_records[1], # Mercedes
    start_time: 1.day.from_now + 9.hours,
    end_time: 1.day.from_now + 11.hours,
    status: 'confirmed'
  },
  {
    phone_number: '+91-9000000009',
    user: user_records[8], # Charlie Designer
    room: room_records[10], # Conference One
    start_time: 1.day.from_now + 14.hours,
    end_time: 1.day.from_now + 16.hours,
    status: 'confirmed'
  },
  {
    phone_number: '+91-9000000010',
    user: user_records[9], # Diana Manager
    room: room_records[2], # BMW
    start_time: 2.days.from_now + 10.hours,
    end_time: 2.days.from_now + 12.hours,
    status: 'cancelled'
  },
  {
    phone_number: '+91-9000000007',
    user: user_records[6], # Alice Employee
    room: room_records[3], # Alto
    start_time: 3.days.from_now + 15.hours,
    end_time: 3.days.from_now + 16.hours,
    status: 'confirmed'
  }
]

bookings_data.each do |booking_data|
  Booking.find_or_create_by!(
    user: booking_data[:user],
    room: booking_data[:room],
    start_time: booking_data[:start_time]
  ) do |booking|
    booking.assign_attributes(booking_data.except(:user, :room))
  end
end

# 10. Create Day Passes
puts "🎫 Creating day passes..."
day_passes_data = [
  {
    workspace: workspace_records[0],
    name: 'Rajesh Kumar',
    phone_number: '+91-9123456789',
    email: 'rajesh@gmail.com',
    pass_date: Date.current,
    purpose: 'Client meeting with SR Next team',
    company_name: 'External Client Corp'
  },
  {
    workspace: workspace_records[0],
    name: 'Priya Sharma',
    phone_number: '+91-9123456790',
    email: 'priya.sharma@consultant.com',
    pass_date: Date.tomorrow,
    purpose: 'Technical consultation',
    company_name: 'Freelance Consultant'
  },
  {
    workspace: workspace_records[1],
    name: 'Amit Patel',
    phone_number: '+91-9123456791',
    email: 'amit@vendor.com',
    pass_date: Date.current + 2.days,
    purpose: 'Product demonstration',
    company_name: 'Tech Vendor Solutions'
  },
  {
    workspace: workspace_records[2],
    name: 'Sneha Gupta',
    phone_number: '+91-9123456792',
    email: 'sneha@interview.com',
    pass_date: Date.current + 3.days,
    purpose: 'Job interview',
    company_name: 'Job Seeker'
  }
]

day_passes_data.each do |day_pass_data|
  DayPass.find_or_create_by!(
    name: day_pass_data[:name],
    phone_number: day_pass_data[:phone_number],
    pass_date: day_pass_data[:pass_date]
  ) do |day_pass|
    day_pass.assign_attributes(day_pass_data.except(:workspace))
    day_pass.workspace_id = day_pass_data[:workspace].id
  end
end

# 11. Create Office Enquiries
puts "💼 Creating office enquiries..."
office_enquiries_data = [
  {
    workspace: workspace_records[0],
    enquirer_name: 'Rohit Agarwal',
    phone_number: '+91-9234567890',
    email: 'rohit@newstartup.com',
    requirement: 'Dedicated desk for 5 people',
    company_name: 'New Startup Pvt Ltd'
  },
  {
    workspace: workspace_records[1],
    enquirer_name: 'Kavita Singh',
    phone_number: '+91-9234567891',
    email: 'kavita@expandingbiz.com',
    requirement: 'Private office for 10 team members',
    company_name: 'Expanding Business Co'
  },
  {
    workspace: workspace_records[2],
    enquirer_name: 'Vikram Rao',
    phone_number: '+91-9234567892',
    email: 'vikram@freelancer.in',
    requirement: 'Hot desk for individual use',
    company_name: 'Freelancer'
  },
  {
    workspace: workspace_records[0],
    enquirer_name: 'Anita Joshi',
    phone_number: '+91-9234567893',
    email: 'anita@consultancy.com',
    requirement: 'Meeting room access twice a week',
    company_name: 'Consultancy Services Ltd'
  }
]

office_enquiries_data.each do |enquiry_data|
  OfficeEnquiry.find_or_create_by!(
    enquirer_name: enquiry_data[:enquirer_name],
    phone_number: enquiry_data[:phone_number]
  ) do |enquiry|
    enquiry.assign_attributes(enquiry_data.except(:workspace))
    enquiry.workspace_id = enquiry_data[:workspace].id
  end
end

# 12. Create Visitor Entries
puts "🚪 Creating visitor entries..."
visitor_entries_data = [
  {
    name: 'Suresh Chandra',
    workspace: workspace_records[0],
    phone_number: '+91-9345678901',
    email: 'suresh@delivery.com',
    purpose: 'Package delivery for SR Next'
  },
  {
    name: 'Meera Kumari',
    workspace: workspace_records[0],
    phone_number: '+91-9345678902',
    email: 'meera@maintenance.com',
    purpose: 'AC maintenance check'
  },
  {
    name: 'Ravi Kumar',
    workspace: workspace_records[1],
    phone_number: '+91-9345678903',
    email: 'ravi@interview.in',
    purpose: 'Job interview with InnovateCorp'
  },
  {
    name: 'Pooja Mishra',
    workspace: workspace_records[2],
    phone_number: '+91-9345678904',
    email: 'pooja@visitor.com',
    purpose: 'Meeting with startup team'
  },
  {
    name: 'Deepak Verma',
    workspace: workspace_records[0],
    phone_number: '+91-9345678905',
    email: 'deepak@client.com',
    purpose: 'Project discussion'
  }
]

visitor_entries_data.each do |visitor_data|
  VisitorEntry.find_or_create_by!(
    name: visitor_data[:name],
    phone_number: visitor_data[:phone_number]
  ) do |visitor|
    visitor.assign_attributes(visitor_data.except(:workspace))
    visitor.workspace_id = visitor_data[:workspace].id
  end
end

puts "✅ Database seeding completed successfully!"
puts
puts "📊 Summary of created records:"
puts "- Companies: #{Company.count}"
puts "- Workspaces: #{Workspace.count}"
puts "- Users: #{User.count}"
puts "  • Super Admins: #{User.super_admin.count}"
puts "  • Admins: #{User.admin.count}"
puts "  • Floor Users: #{User.floor_user.count}"
puts "  • Regular Users: #{User.user.count}"
puts "- Rooms: #{Room.count}"
puts "- Bookings: #{Booking.count}"
puts "- Day Passes: #{DayPass.count}"
puts "- Office Enquiries: #{OfficeEnquiry.count}"
puts "- Visitor Entries: #{VisitorEntry.count}"
puts "- Company-User associations: #{CompanyUser.count}"
puts "- Company-Workspace associations: #{CompanyWorkspace.count}"
puts "- Company-Room associations: #{CompanyRoom.count}"
puts "- User-Workspace associations: #{UserWorkspace.count}"
puts
puts "🔑 All users have been created with password: 123456789"
puts "📧 Test login credentials:"
puts "  Super Admin: superadmin@workspace.com"
puts "  Admin: admin@srnext.in"
puts "  Floor User: floor_user@gmail.com"
puts "  Regular User: user1@srnext.in"
