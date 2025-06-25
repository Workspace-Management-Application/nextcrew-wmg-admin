class Api::BaseController < ApplicationController
  before_action :ensure_token_auth!
  respond_to :json

  private

  # Ensure that only token-based authentication is allowed for API endpoints
  def ensure_token_auth!
    auth_header = request.headers['Authorization']
    
    # Check if the Authorization header is missing or not in 'Bearer <token>' format
    unless auth_header.present? && auth_header.match?(/^Bearer /)
      return render_unauthorized('Authorization token is missing or invalid')
    end

    # Extract the token from the Authorization header
    token = auth_header.split(' ').last

    begin
      # Replace 'your_jwt_secret' with your actual secret key (stored securely, e.g., in Rails credentials)
      decoded_token = JWT.decode(token, Rails.application.credentials.devise_jwt_secret_key, true, { algorithm: 'HS256' })
      payload = decoded_token[0]
      user_id = payload['sub']
      jti = payload['jti'] # JWT ID

      # Check if the token has been revoked
      if JwtDenylist.exists?(jti: jti)
        return render_unauthorized('Token has been revoked')
      end

      @current_user = User.find_by(id: user_id)

      # Ensure that the user exists for the provided token
      unless @current_user
        return render_unauthorized('User not found for provided token')
      end

    # Handle expired token error
    rescue JWT::ExpiredSignature
      return render_unauthorized('Token has expired')

    # Handle invalid token signature or failed verification
    rescue JWT::VerificationError, JWT::DecodeError
      return render_unauthorized('Invalid token')

    # Handle any other exceptions that might arise
    rescue => e
      return render_unauthorized("Authorization failed: #{e.message}")
    end
  end

  # Helper method to render unauthorized response with custom message
  def render_unauthorized(message = 'Unauthorized')
    render json: { error: message }, status: :unauthorized
  end

  # Helper to access the current user (set by the ensure_token_auth! method)
  def current_user
    @current_user
  end

  # Method to render a standard error response
  def render_error(message, status = :unprocessable_entity)
    render json: { message: message }, status: status
  end

  # Method to render a successful response
  def render_success(data, message = "success" , status = :ok)
    render json: { data: data.as_json(except: [:created_at, :updated_at]), message: message }, status: status
  end
end
