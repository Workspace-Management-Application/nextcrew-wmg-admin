class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: :api_request?

  def after_sign_in_path_for(resource)
    if resource.admin? || resource.super_admin?
      admin_root_path
    else
      root_path
    end
  end

  private

  def api_request?
    request.content_type == 'application/json' || request.path.start_with?('/api')
  end
end