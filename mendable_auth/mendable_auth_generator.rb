class MendableAuthGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions "User", "UserTest"

      # Controllers
      m.file 'session_controller.rb', 'app/controllers/session_controller.rb'
      m.file 'users_controller.rb', 'app/controllers/users_controller.rb'

      # Models
      m.file 'user.rb', 'app/models/user.rb'
      m.file 'email.rb', 'app/models/email.rb'

      # Views
      m.directory 'app/views/session'
      m.directory 'app/views/users'
      m.directory 'app/views/email'
      m.file 'login.html.erb', 'app/views/session/new.html.erb'
      %w{new edit index show}.each do |file|
        m.file "#{file}.html.erb", "app/views/users/#{file}.html.erb"
      end
      m.file 'signup.erb', 'app/views/email/signup.erb'

      # Migrations
      m.migration_template 'db/migrate/create_users.rb', 'db/migrate', :assigns => {:table_name => "users", :class_name => "User"}, :migration_file_name => "create_users"

      # Tests
      m.file 'test/user_test.rb', 'test/unit/user_test.rb'
      m.file 'test/session_controller_test.rb', 'test/functional/session_controller_test.rb'      
      m.file 'test/users_controller_test.rb', 'test/functional/users_controller_test.rb'

      # Factories
      m.directory 'test/factories'
      m.file 'test/factories/user.rb', 'test/factories/user.rb'

      # Routes
      routes_to_add = <<-END
  map.resource :session,  :controller => 'session'
  map.resources :users

  map.login '/login',     :controller => 'session', :action => 'new'
  map.logout '/logout',   :controller => 'session', :action => 'destroy'
  map.signup '/signup',   :controller => 'users', :action => 'new'
END
      add_to_routes(routes_to_add)
 
     
      # Application Controller
      code_to_add = <<-END
  # Returns the currently logged in user, otherwise nil/false.
  def current_user
    return nil if not logged_in?
    User.find(session[:user_id])
  end

  helper_method :logged_in?
  # Is the user currently logged in, or are they browsing as a guest? Returns
  # true/false accordingly.
  def logged_in?
    session[:user_id] && session[:user_id].to_i > 0 ? true : false
  end

  # before_filter to ensure a user is logged in before accessing specified actions.
  def login_required
    if !logged_in? then
      flash[:notice] = "You need to sign up or log in before seeing this page."
      redirect_to login_url
      return false
    end
    return true
  end
END
      add_to_application_controller(code_to_add)


      # Test helper
      code_to_add = <<-END
  def login_as(user)
    @request.session[:user_id] = user.id
  end

 def self.should_require_login(method, action, params={})
    method = method.to_s.downcase
    context "'\#{method.upcase}' method on '\#{action}' action" do
      setup do
        case method
          when "get"   : get(action, params)
          when "post"  : post(action, params)
          when "put"   : put(action, params)
          when "delete": delete(action, params)
          else raise "\#{method.upcase} is an unknown HTTP method"
        end
      end

      should "require login" do
        assert_redirected_to login_url
      end
    end
  end
END
      add_to_test_helper(code_to_add)
    end
  end 


  protected
    def exists_in_file?(relative_destination, string)
      path = destination_path(relative_destination)
      content = File.read(path)
      return content.include?(string)
    end

    def gsub_file(relative_destination, regexp, *args, &block)
      path = destination_path(relative_destination)
      content = File.read(path).gsub(regexp, *args, &block)
      File.open(path, 'wb') { |file| file.write(content) }
    end


    def add_to_file(filename, starting_point, addition)
      return if exists_in_file?(filename, addition)
      
      gsub_file filename, /(#{Regexp.escape(starting_point)})/mi do |match|
        "#{match}\n#{addition}\n"
      end
    end
    
    def add_to_test_helper(helper_code)
      add_to_file('test/test_helper.rb', 'class ActiveSupport::TestCase', helper_code)
    end

    def add_to_routes(route_text)
      add_to_file('config/routes.rb', 'ActionController::Routing::Routes.draw do |map|', route_text)
    end

    def add_to_application_controller(helper_code)
      add_to_file('app/controllers/application_controller.rb', 'class ApplicationController < ActionController::Base', helper_code)
    end

end
