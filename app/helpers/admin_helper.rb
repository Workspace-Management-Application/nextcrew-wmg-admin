module AdminHelper
  def current_admin_page?(controller_name, action_name = nil)
    current_page?(controller: "admin/#{controller_name}", action: action_name || params[:action])
  end

  def admin_nav_active?(controller_names)
    controller_names = Array(controller_names)
    controller_names.include?(controller_name)
  end

  def pagination_info(collection, resource_name = nil)
    # Auto-detect resource name if not provided
    if resource_name.nil?
      resource_name = collection.model.name.downcase.pluralize rescue "items"
    end
    
    if collection.any?
      start_num = collection.offset_value + 1
      end_num = [collection.offset_value + collection.limit_value, collection.total_count].min
      "Showing #{start_num} to #{end_num} of #{collection.total_count} #{resource_name}"
    else
      "No #{resource_name} found"
    end
  end
end
