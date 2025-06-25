class Api::UserController < Api::BaseController
  # GET /api/get_profile
  def get_profile
    token = request.headers['Authorization']&.split(' ')&.last
    begin
      payload = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key)[0]
      user = User.find_by(id: payload['sub'])
      data = user.as_json.merge(workspace_id: user.workspace&.id)
      if user
        render_success(data)
      else
        render_error('User not found', :unauthorized)
      end
    rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError => e
      render_error('Invalid or expired token')
    end
  end
end 