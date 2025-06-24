class Api::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }
  respond_to :json

  # POST /api/login
  def create
    self.resource = warden.authenticate!(scope: :user)
    sign_in(resource_name, resource)
    data = {}
    data = {
      token: request.env['warden-jwt_auth.token'],
      user: resource.as_json(only: [:id, :email, :name]),
      workspace_id: resource.workspace&.id
    }

    render json:{ message: 'Logged in successfully', data: data }, status: :ok
  end

  # DELETE /api/logout
  def destroy
    token = request.headers['Authorization']&.split(' ')&.last
    payload = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key).first
    
    if payload
      # Create denylist entry unless it already exists
      unless JwtDenylist.exists?(jti: payload['jti'])
        JwtDenylist.create!(
          jti: payload['jti'],
          exp: Time.at(payload['exp'])
        )
      end
    end
    render json: { message: 'Logged out successfully.' }, status: :ok
  end

  private

  def respond_to_on_destroy
    head :no_content
  end
end
