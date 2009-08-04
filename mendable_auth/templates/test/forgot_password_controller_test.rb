require File.dirname(__FILE__) + '/../test_helper'

class ForgotPasswordControllerTest < ActionController::TestCase

  context "viewing forgot password page" do
    setup do
      get :new
    end
    should_respond_with :success
    should_render_template :new
    should_not_set_the_flash
  end


  context "Creating a forgot password request" do
    context "with a valid email address" do
      setup do
        @user = Factory(:user)
        ActionMailer::Base.deliveries.clear
        post :create, :email => @user.email
      end

      should "send an email to that email address" do
        assert_sent_email {|email| email.to.include?(@user.email) }
      end
      
      should_set_the_flash_to "An email has been sent to your email address, please check the email for instructions."
      should_redirect_to("login page") { login_url }
    end

    context "with a non-existant email address" do
      setup do
        ActionMailer::Base.deliveries.clear
        post :create, :email => 'doesnotexist@example.com'
      end
      should_respond_with :success
      should_render_template :new
      should_set_the_flash_to "The email address you entered could not be found"
      should "not send any emails" do
        assert_equal 0, ActionMailer::Base.deliveries.size
      end
    end
  end


  context "Accessing the reset password page" do
    context "with an invalid user id specified" do
      setup do
        get :edit, :id => 1
      end
      should_set_the_flash_to "The user could not be found"
      should_redirect_to("reset password page") { forgot_password_reset_url }
    end

    context "for a valid user" do
      setup do 
        @user = Factory(:user, :password => "password")
      end

      context "with an invalid reset code" do
        setup do
          get :edit, :id => @user, :c => "invalid"
        end
        should_set_the_flash_to "The reset code is not valid. Please reset your password again, only using the new link we email to you"
        should_redirect_to("reset password page") { forgot_password_reset_url }
      end

      context "with a valid reset code" do
        setup do
          get :edit, :id => @user, :c => @user.password_reset_code
        end

        should_assign_to :user
        should_respond_with :success
        should_render_template :edit
        should_not_set_the_flash
      end
    end
  end

  
  context "Attempting to update the password" do
    context "with an invalid user id specified" do
      setup do
        put :update, :id => 1
      end
      should_set_the_flash_to "The user could not be found"
      should_redirect_to("reset password page") { forgot_password_reset_url }
    end

    context "for a valid user" do
      setup do
        @user = Factory(:user, :password => "password")
      end

      context "with an invalid reset code" do
        setup do
          put :update, :id => @user, :c => "invalid", :password => "newpass"
        end
        should_set_the_flash_to "The reset code is not valid. Please reset your password again, only using the new link we email to you"
        should_redirect_to("reset password page") { forgot_password_reset_url }
        should "not update the password" do
          @user.reload
          assert_equal @user.password, "password"
        end
      end

      context "with a valid reset code" do
        setup do
          put :update, :id => @user, :c => @user.password_reset_code, :password => "newpassword"
        end

        should "update the users password" do
          @user.reload
          assert_equal @user.password, "newpassword" 
        end

        should_redirect_to("login page") { login_url }
        should_set_the_flash_to "Password successfully changed - Please login"
      end
    end
  end

end
