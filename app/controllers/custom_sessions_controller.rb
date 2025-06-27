class CustomSessionsController < Devise::SessionsController
  def create
    # Get the user by email before authentication
    email = params.dig(:user, :email)
    
    if email.present?
      user = User.find_by(email: email.downcase.strip)
      
      # Check if user exists and is mobile-only
      if user && user.mobile_only?
        # Set flash message and redirect back to sign in
        flash[:alert] = "You can't login through the web. Please use the mobile app."
        redirect_to new_user_session_path and return
      end
    end
    
    # If user is allowed (admin or super_admin), proceed with normal authentication
    super
  end

  protected

  # Override after_sign_in_path to redirect to admin dashboard
  def after_sign_in_path_for(resource)
    if resource.can_access_web?
      admin_dashboard_path
    else
      # This shouldn't happen due to the check above, but just in case
      sign_out resource
      flash[:alert] = "You can't login through the web. Please use the mobile app."
      new_user_session_path
    end
  end

  # Additional check to ensure only valid users can authenticate
  def authenticate_scope!
    super
    
    # Double-check after authentication
    if current_user && current_user.mobile_only?
      sign_out current_user
      flash[:alert] = "You can't login through the web. Please use the mobile app."
      redirect_to new_user_session_path
    end
  end
end
