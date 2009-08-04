class SessionController < ApplicationController

  # show login page
  def new
    if logged_in? then
      redirect_to root_url
    end
  end

  # process login credentials
  def create
    auth_user = User.authenticate(params[:email], params[:password])
    
    if auth_user then
      set_current_user auth_user
      flash[:notice] = "Login Successful"
      redirect_to root_url
    else # authentication failed
      flash[:error] = "Unable to login, please check your details and try again"
      render :new
    end
  end

  # logout
  def destroy
    session[:user_id] = nil
    flash[:notice] = "Logout Successful"
    redirect_to root_url
  end

end
