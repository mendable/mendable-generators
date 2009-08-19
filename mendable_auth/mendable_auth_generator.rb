class MendableAuthGenerator < Rails::Generator::Base
  default_options :with_simple_admin => false

  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions "User", "UserTest"

      # Controllers
      m.file 'session/session_controller.rb', 'app/controllers/session_controller.rb'
      m.file 'user/users_controller.rb', 'app/controllers/users_controller.rb'
      m.file 'forgot_password/forgot_password_controller.rb', 'app/controllers/forgot_password_controller.rb'

      # Models
      m.template 'user/user.rb', 'app/models/user.rb'
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
      m.template 'mendable_auth.rb', 'lib/mendable_auth.rb'
      m.template 'test/mendable_auth_test_helper.rb', 'lib/mendable_auth_test_helper.rb'
    
      # Migrations
      m.migration_template 'db/migrate/create_users.rb', 'db/migrate', :assigns => {:table_name => "users", :class_name => "User"}, :migration_file_name => "create_users"

      # Tests
      m.template 'test/user_test.rb', 'test/unit/user_test.rb'
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
      add_to_application_controller("  include MendableAuth::Controller")

      # Test helper
      add_to_test_helper_requires("require 'mendable_auth_test_helper'")

      # Environment
      add_to_environment("  config.gem 'bcrypt-ruby', :lib => 'bcrypt'")
    end
  end 


  protected
    def banner
      "Usage: #{$0} mendable_auth"
    end

    def add_options!(opt)
      opt.separator ''
      opt.separator 'Options:'
      opt.on("--with-simple-admin", "Includes is_admin? field and admin helpers") { |v| options[:with_simple_admin] = v }
    end



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

    def add_to_test_helper_requires(require_lines)
      add_to_file('test/test_helper.rb', "require 'test_help'", require_lines)
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
