require File.dirname(__FILE__) + '/../test_helper'

class SessionControllerTest < ActionController::TestCase

  context 'viewing login page' do
    context "when not logged in" do
      setup do
        get :new
      end
      should_respond_with :success
      should_render_template :new
      should_not_set_the_flash
    end

    context "when already logged in" do
      setup do
        @user = Factory(:user)
        login_as @user
        get :new
      end

      should_redirect_to("homepage") { root_url }
      should_not_set_the_flash
    end
  end


  context 'attempting login' do
    context "with a valid user" do
      setup do 
        @password = "letmein"
        @user = Factory(:user, :password => @password)
      end

      context "using correct login details" do
        setup do
          post :create, :email => @user.email, :password => @password
        end

        should_redirect_to("homepage") { root_url }
        should_set_the_flash_to "Login Successful"
        
        should "set the user's id in the session" do
          assert_equal @user.id, session[:user_id]
        end
      end

      context "but incorrect password" do
        setup do
          post :create, :email => @user.email, :password => "incorrect"
        end
        
        should_respond_with :success
        should_render_template :new
        should_set_the_flash_to "Unable to login, please check your details and try again"

        should "not set a user id in the session" do
          assert_nil session[:user_id]
        end
      end
    end

    context "with non-existant user" do
      setup do
        post :create, :email => "does_not_exist@example.com", :password => "foobar"
      end
      should_respond_with :success
      should_render_template :new
      should_set_the_flash_to "Unable to login, please check your details and try again"

      should "not set a user id in the session" do
        assert_nil session[:user_id]
      end
    end
  end


  context 'logging out' do
    setup do 
      get :destroy 
    end
    
    should "set session user id to nil" do
      assert_nil session[:user_id]
    end

    should_set_the_flash_to "Logout Successful"
    should_redirect_to("homepage") { root_url }
  end
end
