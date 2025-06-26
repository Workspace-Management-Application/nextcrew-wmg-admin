module AdminHelper
  def current_admin_page?(controller_name, action_name = nil)
    current_page?(controller: "admin/#{controller_name}", action: action_name || params[:action])
  end

  def admin_nav_active?(controller_names)
    controller_names = Array(controller_names)
    controller_names.include?(controller_name)
  end
end
