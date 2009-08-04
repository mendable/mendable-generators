# Act as if forgot password requests are a resource that can be created
class ForgotPasswordController < ApplicationController

  before_filter :find_valid_user_else_redirect, :only => [:edit, :update]

  # Show the forgot password page
  def new
  end

  # Send password email
  def create
     user = User.find_by_email(params[:email])

    if user then # found corresponding user
      Email.deliver_forgot_password(user)
      flash[:notice] = "An email has been sent to your email address, please check the email for instructions."
      redirect_to login_url
    else # email address not found
      flash[:error] = "The email address you entered could not be found"
      render :new
    end
  end
 
  # Allow user to enter new password
  def edit
  end
  
  # Save the new password
  def update
    @user.password = params[:password]
    if @user.save then
      flash[:notice] = "Password successfully changed - Please login"
      redirect_to login_url
    end
  end


  protected 
    def find_valid_user_else_redirect
      @user = User.find(params[:id])

      if @user.password_reset_code != params[:c] then
        flash[:error] = "The reset code is not valid. Please reset your password again, only using the new link we email to you"
        redirect_to forgot_password_reset_url
      end
    rescue ActiveRecord::RecordNotFound
      flash[:error] = "The user could not be found"
      redirect_to forgot_password_reset_url
    end
end
