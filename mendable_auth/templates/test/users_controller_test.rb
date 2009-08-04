require File.dirname(__FILE__) + '/../test_helper'

class UsersControllerTest < ActionController::TestCase
  
  context "Users Controller" do
    should_require_login :get, :index
    should_require_login :get, :show, {:id => 1}
    should_require_login :get, :edit, {:id => 1}
    should_require_login :put, :update, {:id => 1}
    should_require_login :delete, :destroy, {:id => 1}
  end


  context "GET on index page" do
    setup do
      login_as Factory(:user)
      get :index
    end
    should_respond_with :success
    should_assign_to :users
    should_not_set_the_flash
  end

  
  context "GET on show page" do
    setup do
      @user = Factory(:user)
      login_as @user
      get :show, :id => @user.id
    end

    should_respond_with :success
    should_assign_to :user
    should_not_set_the_flash
    should_render_template :show
  end


  context "GET to signup page" do
    setup do
      get :new
    end

    should_assign_to :user
    should_respond_with :success
    should_render_template :new
    should_not_set_the_flash
  end
  
  
  context "POST on signup page" do
    context "with valid details" do
      setup do
        post :create, :user => Factory.attributes_for(:user)
        @user = User.find(:all).last
      end

      should_change('User.count', :by => 1) { User.count }
      should "set the user's id in the session" do
        assert_equal @user.id, session[:user_id]
      end
      should_set_the_flash_to "User was successfully created."
      should_redirect_to('show path') { user_path(@user) }
    end

    context "with invalid details" do
      setup do 
        post :create, :username => "$$invalid$$", :email => "", :password => ""
      end
      
      should_respond_with :success
      should_render_template :new
      should_not_set_the_flash
      should_assign_to :user
      should "have errors on invalid params" do
        %w{username email password}.each do |field| 
          assert assigns(:user).errors.on(field.to_sym)
        end
      end
    end
  end
 

  context 'GET to edit' do
    setup do
      @user = Factory(:user)
      login_as @user
      get :edit, :id => @user.id
    end
    should_respond_with :success
    should_render_template :edit
    should_assign_to :user
  end
 

  context 'PUT to update' do
    context "with an attribute, such as email address" do
      setup do
        @email = "valid2@example.com"
        @user = Factory(:user, :email => "valid1@example.com")
        login_as @user
        put :update, :id => @user.id, :user => {:email => @email}
      end

      should "update that attribute in the database" do
        @user.reload
        assert_equal @user.email, @email
      end

      should_set_the_flash_to "User was successfully updated."
      should_redirect_to('show path') { user_path(@user) }
    end

    context "with invalid details (eg, empty email)" do
      setup do
        @user = Factory(:user)
        login_as @user
        put :update, :id => @user.id, :user => {:email => ""}
      end
      
      should_respond_with :success
      should_render_template :edit
      should_assign_to :user

      should "have errors on invalid params" do
        %w{email}.each do |field|
          assert assigns(:user).errors.on(field.to_sym)
        end
      end
    end
  end


  context 'DELETE to destroy' do
    setup do
      @user = Factory(:user)
      login_as @user
      delete :destroy, :id => @user.id
    end
    
    should "delete user" do
      assert_nil User.find(:first, :conditions => ["id = ?", @user.id])
    end
    should_redirect_to('index path') { users_path }
  end

end
