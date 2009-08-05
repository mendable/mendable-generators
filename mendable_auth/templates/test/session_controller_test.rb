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

        should "set the user's id in the session" do
          assert_equal @user.id, session[:user_id]
        end
        should_redirect_to("homepage") { root_url }
        should_set_the_flash_to "Login Successful" 
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

      context "with remember me" do
        setup do
          @request.cookies["auth_token"] = nil
          post :create, :email => @user.email, :password => @password, :remember_me => "1"
        end

        should "set auth token" do
          assert_not_nil @response.cookies["auth_token"]
        end
      end

      context "without remember me" do
        setup do
          @request.cookies["auth_token"] = nil
          post :create, :email => @user.email, :password => 'monkey', :remember_me => "0"
        end

        should "not set auth token" do
          assert @response.cookies["auth_token"].blank?
        end
      end

      context "with cookie" do
        setup do
          @user.remember_me
          @request.cookies["auth_token"] = cookie_for(@user)
          session[:user_id] = nil
          get :new
          # important: have not otherwise logged in, so session[:user_id] not set
        end

        should "automatically be logged in" do
          assert @controller.send(:logged_in?)
        end

        should "correctly know the current user" do
          assert_equal @user, @controller.send(:current_user)
        end
      end

      context "with expired cookie" do
        setup do
          @user.remember_me
          @user.update_attribute :remember_token_expires_at, 5.minutes.ago
          @request.cookies["auth_token"] = cookie_for(@user)
          get :new
        end

        should "not auto log in" do
          assert !@controller.send(:logged_in?)
        end
      end

      context "with invalid cookie" do
        setup do
          @user.remember_me
          @request.cookies["auth_token"] = auth_token('invalid_auth_token')
          get :new
        end

        should "not auto log in" do
          assert !@controller.send(:logged_in?)
        end
      end
    end # with valid user

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
  end #logging in


  context 'logging out' do
    setup do 
      @user = Factory(:user)
      login_as @user
      get :destroy 
    end
    
    should "set session user id to nil" do
      assert_nil session[:user_id]
    end

    should "delete token" do
      assert @response.cookies["auth_token"].blank?
    end

    should "not be logged in any more" do
      assert !@controller.send(:logged_in?)
    end

    should_set_the_flash_to "Logout Successful"
    should_redirect_to("homepage") { root_url }


    context "with remember token" do
      setup do
        @user.remember_me
        @request.cookies["auth_token"] = cookie_for(@user)
      end
      
      should "destroy cookie token" do
        assert @response.cookies["auth_token"].blank?
      end

      should "not be logged in any more" do
        assert !@controller.send(:logged_in?)
      end
    end
  end


  protected
    def auth_token(token)
      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
    end

    def cookie_for(user)
      auth_token user.remember_token
    end

end
