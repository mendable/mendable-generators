class MendableAuthGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions "User", "UserTest"

      # Controllers
      m.file 'session_controller.rb', 'app/controllers/session_controller.rb'

      # Models
      m.file 'user.rb', 'app/models/user.rb'

      # Views
      m.directory 'app/views/session'
      m.file 'login.html.erb', 'app/views/session/new.html.erb'

      # Migrations
      m.migration_template 'db/migrate/create_users.rb', 'db/migrate', :assigns => {:table_name => "users", :class_name => "User"}, :migration_file_name => "create_users"

      # Tests
      m.file 'test/user_test.rb', 'test/unit/user_test.rb'
      m.file 'test/session_controller_test.rb', 'test/functional/session_controller_test.rb'      

      # Factories
      m.directory 'test/factories'
      m.file 'test/factories/user.rb', 'test/factories/user.rb'

      # Routes
      routes_to_add = <<-END
  map.resource :session,  :controller => 'session'
  map.login '/login',     :controller => 'session', :action => 'new'
  map.logout '/logout',   :controller => 'session', :action => 'destroy'
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
END
      add_to_application_controller(code_to_add)
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

    def add_to_routes(route_text)
      filename = 'config/routes.rb'

      return if exists_in_file?(filename, route_text)

      sentinel = 'ActionController::Routing::Routes.draw do |map|'
      gsub_file filename, /(#{Regexp.escape(sentinel)})/mi do |match|
        "#{match}\n#{route_text}\n"
      end
    end

    def add_to_application_controller(helper_code)
      filename = 'app/controllers/application_controller.rb'

      return if exists_in_file?(filename, helper_code)

      sentinel = 'class ApplicationController < ActionController::Base'
      gsub_file filename, /(#{Regexp.escape(sentinel)})/mi do |match|
        "#{match}\n#{helper_code}\n"
      end
    end

end
