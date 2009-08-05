class SessionController < ApplicationController

  # show login page
  def new
    if logged_in? then
      redirect_to root_url
    end
    
    store_location(params[:r]) if params[:r]
  end

  # process login credentials
  def create
    auth_user = User.authenticate(params[:email], params[:password])
    
    if auth_user then
      set_current_user auth_user

      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag

      flash[:notice] = "Login Successful"
      redirect_back_or_default root_url
    else # authentication failed
      flash[:error] = "Unable to login, please check your details and try again"
      @remember_me = params[:remember_me]
      render :new
    end
  end

  # logout
  def destroy
    logout_killing_session!
    flash[:notice] = "Logout Successful"
    redirect_to root_url
  end

end
