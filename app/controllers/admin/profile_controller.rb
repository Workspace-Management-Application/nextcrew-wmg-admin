class Admin::ProfileController < Admin::BaseController
  def show
    @user = current_user
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    
    if @user.update(profile_params)
      redirect_to admin_profile_path, notice: 'Profile was successfully updated.'
    else
      render :edit
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email, :phone, :avatar)
  end
end
