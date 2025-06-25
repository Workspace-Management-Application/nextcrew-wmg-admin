class Api::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }
  respond_to :json

  # POST /api/login
  def create
    # Find user by email, if not found return 404
    user = User.find_by_email(params[:user][:email])

    # Handle case where user doesn't exist
    if user.nil?
      return render json: { error: 'User not found' }, status: :not_found
    end

    # Validate user password
    if user.valid_password?(params[:user][:password])
      # Skip the warden.authenticate! since we already validated the password
      sign_in(resource_name, user)
      refresh_token = SecureRandom.hex(32)
      resource.update(refresh_token: refresh_token)
 
      # Prepare data to send back in the response
      data = {
        token: request.env['warden-jwt_auth.token'],  # Get JWT token
        user: user.as_json(only: [:id, :email, :name]),  # Only expose essential fields
        refresh_token: refresh_token,
        workspace_id: user.workspace&.id  # Get associated workspace if exists
      }

      # Send success response
      render json: { message: 'Logged in successfully', data: data }, status: :ok
    else
      # Invalid password error response
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
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

  # POST /api/refresh_token
  def refresh_token
    provided_refresh_token = params[:refresh_token]
    user = User.find_by(refresh_token: provided_refresh_token)

    if user.nil?
      return render json: { error: 'Invalid refresh token' }, status: :unauthorized
    end

    # Generate a new JWT token for the user
    sign_in(:user, user)
    new_access_token = request.env['warden-jwt_auth.token']
    new_refresh_token = SecureRandom.hex(32)
    user.update(refresh_token: new_refresh_token)

    data = {
      token: new_access_token,
      refresh_token: new_refresh_token
    }

    render json: { message: 'Token refreshed successfully', data: data }, status: :ok
  end
end
