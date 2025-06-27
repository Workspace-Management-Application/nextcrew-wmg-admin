class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, unless: :api_request?

  private

  def api_request?
    request.content_type == 'application/json' || request.path.start_with?('/api')
  end
end