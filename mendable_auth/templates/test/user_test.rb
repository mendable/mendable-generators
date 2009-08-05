require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  
  should_not_allow_mass_assignment_of :id
  
  # Validate username field as being in our correct format. 
  should_ensure_length_in_range :username, 4..50
  should_allow_values_for :username, *%w{bob33 baz09 baz0- abcdefg13098875 -fa539 48xx5fi}
  should_not_allow_values_for :username, *%w{sht aa$12 %percent ^aaa #234ff [42fa 5ffa] 1af1" yya*}
  should_not_allow_values_for :username, ' ' # Don't allow technically empty usernames where user just tried to put a space


  # Validate email field
  context "A valid user" do
    setup { Factory(:user) }
    should_validate_uniqueness_of :email, :message => "An account with this email address already exists"
    should_validate_uniqueness_of :username
  end
  should_allow_values_for :email, *%w{com org new edu es jp info co.uk org.uk}.collect{|ending|  "foo.var_1-9@baz-quux0.example.#{ending}" }
  should_allow_values_for :email, *%w{foobar@example.com foobar@example.co.uk foobar@mail.example.com foo_bar@example.com}
  should_not_allow_values_for :email, *%w{foobar@example.c @example.com @fcom foo@bar..com foobar@example.infod foobar.example.com foo@ex(ample.com foo@example,com}

  # Confirm password enforces a reasonable length constraint
  #should_ensure_length_in_range :password, 4..16


  context "attempting authentication" do
    context "for an existing user" do
      setup do
        @password = "password".downcase
        @user = Factory(:user, :password => @password)
      end

      should "return user record when correct email and password used" do
        assert_equal @user, User.authenticate(@user.email, @password)
      end
      
      should "be case insensitive and return user record when correct email and password (with case difference) used" do
        assert_equal @user, User.authenticate(@user.email, @password.upcase)
      end
      
      should "return nil when correct email but invalid password used" do
        assert_equal nil, User.authenticate(@user.email, "wrong_password")
      end
    end

    context "for a customer that does not exist" do
      should "return false for User#authenticate" do
        assert_equal nil, User.authenticate("doesnotexist@example.com", "password")
      end
    end
  end


  context "Creating a new user" do
    setup do
      ActionMailer::Base.deliveries.clear
      @user = Factory(:user)
    end

    should "send signup email" do
      assert_sent_email {|email| email.to.include?(@user.email) }
    end
  end


  context "Calling password_reset_code" do
    setup do
      @user = Factory(:user, :password => "password")
    end
    
    should "return a SHA1 Digest of the password field as the reset code" do
      assert_equal Digest::SHA1.hexdigest(@user.crypted_password), @user.password_reset_code
    end
  end


  # Initial defensive test, modify if you do send any emails upon update
  context "updating an existing user" do
    setup do
      @user = Factory(:user)
      ActionMailer::Base.deliveries.clear
      @user.save
    end

    should "not send any emails" do
      assert_equal 0, ActionMailer::Base.deliveries.size
    end
  end


  context "Setting a users password" do
    setup do
      @user = Factory(:user, :crypted_password => "", :password => "password")
      @user.reload
    end

    should "store an encrypted password in the crypted_password field" do
      assert @user.crypted_password != @user.password
      assert_equal 60, @user.crypted_password.length
      assert_match /^\$/, @user.crypted_password
    end
  end

end
