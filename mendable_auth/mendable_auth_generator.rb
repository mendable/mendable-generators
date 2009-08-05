class MendableAuthGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions "User", "UserTest"

      # Controllers
      m.file 'session/session_controller.rb', 'app/controllers/session_controller.rb'
      m.file 'user/users_controller.rb', 'app/controllers/users_controller.rb'
      m.file 'forgot_password/forgot_password_controller.rb', 'app/controllers/forgot_password_controller.rb'

      # Models
      m.file 'user/user.rb', 'app/models/user.rb'
      m.file 'email/email.rb', 'app/models/email.rb'

      # Views
      m.directory 'app/views/session'
      m.directory 'app/views/users'
      m.directory 'app/views/forgot_password'
      m.directory 'app/views/email'
      m.file 'session/new.html.erb', 'app/views/session/new.html.erb'
      %w{new edit index show}.each do |file|
        m.file "user/#{file}.html.erb", "app/views/users/#{file}.html.erb"
      end
      m.file 'forgot_password/new.html.erb', 'app/views/forgot_password/new.html.erb'
      m.file 'forgot_password/edit.html.erb', 'app/views/forgot_password/edit.html.erb'
      m.file 'email/signup.erb', 'app/views/email/signup.erb'
      m.file 'email/forgot_password.erb', 'app/views/email/forgot_password.erb'

      # Libs
      m.file 'mendable_auth.rb', 'lib/mendable_auth.rb'
    
      # Migrations
      m.migration_template 'db/migrate/create_users.rb', 'db/migrate', :assigns => {:table_name => "users", :class_name => "User"}, :migration_file_name => "create_users"

      # Tests
      m.file 'test/user_test.rb', 'test/unit/user_test.rb'
      m.file 'test/session_controller_test.rb', 'test/functional/session_controller_test.rb'      
      m.file 'test/users_controller_test.rb', 'test/functional/users_controller_test.rb'
      m.file 'test/forgot_password_controller_test.rb', 'test/functional/forgot_password_controller_test.rb'

      # Factories
      m.directory 'test/factories'
      m.file 'test/factories/user.rb', 'test/factories/user.rb'

      # Routes
      routes_to_add = <<-END
  map.login '/login',     :controller => 'session', :action => 'new'
  map.logout '/logout',   :controller => 'session', :action => 'destroy'
  map.resource  :session,          :controller => 'session'

  map.forgot_password       'forgot_password', :controller => 'forgot_password', :action => 'new'
  map.forgot_password_reset 'forgot_password/reset/:id', :controller => 'forgot_password', :action => 'edit'
  map.resource :forgot_password, :controller => 'forgot_password'

  map.signup '/signup',   :controller => 'users', :action => 'new'
  map.resources :users

END
      add_to_routes(routes_to_add)
 
     
      # Application Controller
      code_to_add = <<-END
  include MendableAuth::Controller
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

      add_to_environment("  config.gem 'bcrypt-ruby', :lib => 'bcrypt'")
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

    def add_to_environment(helper_code)
      add_to_file('config/environment.rb', 'Rails::Initializer.run do |config|', helper_code)
    end
end
