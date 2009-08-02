class MendableAuthGenerator < Rails::Generator::Base

  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions "User", "UserTest"

      # Controllers

      # Models
      m.file 'user.rb', 'app/models/user.rb'

      # Views

      # Migrations
      m.migration_template 'db/migrate/create_users.rb', 'db/migrate', :assigns => {:table_name => "users", :class_name => "User"}, :migration_file_name => "create_users"

      # Tests
      m.file 'test/unit/user_test.rb', 'test/unit/user_test.rb'
      
      # Factories
      m.directory 'test/factories'
      m.file 'test/factories/user.rb', 'test/factories/user.rb'
    end
  end 

end
