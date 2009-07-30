class MendableScaffoldGenerator < Rails::Generator::NamedBase
  default_options :skip_timestamps => false, :skip_migration => false, :force_plural => false

  attr_reader   :controller_name,
                :controller_class_path,
                :controller_file_path,
                :controller_class_nesting,
                :controller_class_nesting_depth,
                :controller_class_name,
                :controller_underscore_name,
                :controller_singular_name,
                :controller_plural_name,
                :nesting_owner
  alias_method  :controller_file_name,  :controller_underscore_name
  alias_method  :controller_table_name, :controller_plural_name

  def initialize(runtime_args, runtime_options = {})
    super

    @nesting_owner = (options[:owner] || "").underscore.singularize

    if @name == @name.pluralize && !options[:force_plural]
      logger.warning "Plural version of the model detected, using singularized version.  Override with --force-plural."
      @name = @name.singularize
    end

    @controller_name = @name.pluralize

    base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@controller_name)
    @controller_class_name_without_nesting, @controller_underscore_name, @controller_plural_name = inflect_names(base_name)
    @controller_singular_name=base_name.singularize
    if @controller_class_nesting.empty?
      @controller_class_name = @controller_class_name_without_nesting
    else
      @controller_class_name = "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"
    end
  end

  def manifest
    record do |m|
      # Check for class naming collisions.
      m.class_collisions("#{controller_class_name}Controller", "#{controller_class_name}Helper")
      m.class_collisions(class_name)

      # Controller, helper, views, test and stylesheets directories.
      m.directory(File.join('app/models', class_path))
      m.directory(File.join('app/controllers', controller_class_path))
      m.directory(File.join('app/views', controller_class_path, controller_file_name))
      m.directory(File.join('test/functional', controller_class_path))
      m.directory(File.join('test/unit', class_path))

      for action in scaffold_views
        m.template(
          "view_#{action}.html.erb",
          File.join('app/views', controller_class_path, controller_file_name, "#{action}.html.erb")
        )
      end

      m.template(
        (nested? ? 'controller_nested.rb' : 'controller.rb'), File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb")
      )

      m.template('functional_test.rb', File.join('test/functional', controller_class_path, "#{controller_file_name}_controller_test.rb"))

      m.route_resources controller_file_name


      %w{create.png edit.png destroy.png}.each do |image_filename|
        m.file image_filename, "public/images/#{image_filename}"
      end

      helper_code = <<-END
  # mendable_scaffold
  def new_icon
    image_tag 'create.png'
  end
  
  def edit_icon 
    image_tag 'edit.png'
  end

  def destroy_icon
    image_tag 'destroy.png'
  end
  # / mendable_scaffold
END
      m.add_to_application_helper(helper_code)

      m.dependency 'mendable_model', [name] + @args, :collision => :skip
    end
  end

  protected
    # Override with your own usage banner.
    def banner
      "Usage: #{$0} scaffold ModelName [field:type, field:type]"
    end

    def add_options!(opt)
      opt.separator ''
      opt.separator 'Options:'
      opt.on("--skip-timestamps",
             "Don't add timestamps to the migration file for this model") { |v| options[:skip_timestamps] = v }
      opt.on("--skip-migration",
             "Don't generate a migration file for this model") { |v| options[:skip_migration] = v }
      opt.on("--force-plural",
             "Forces the generation of a plural ModelName") { |v| options[:force_plural] = v }
      opt.on("--owner=owner", "Specifys the parent resource") { |v| options[:owner] = v }
    end

    def scaffold_views
      %w[ index show new edit ]
    end

    def model_name
      class_name.demodulize
    end


    # a_eval - decides if to include "@" symbol or nothing based on value passed
    # TODO rename this function to something more descriptive
    def a_eval(f) f ? "@" : "" end

    def index_path 
      nested? ? "#{nesting_owner}_#{plural_name}_path(@#{nesting_owner})" : "#{plural_name}_path"
    end

    def new_path
      nested? ? "new_#{nesting_owner}_#{singular_name}_path(@#{nesting_owner})" : "new_#{singular_name}_path"
    end

    def new_form_path
      nested? ? "[@#{singular_name}.#{nesting_owner}, @#{singular_name}]" : "@#{singular_name}"
    end

    def show_path(a_var = true)
      nested? ? "#{nesting_owner}_#{singular_name}_path(@#{nesting_owner}, #{a_eval(a_var)}#{singular_name})" : "#{a_eval(a_var)}#{singular_name}"
    end

    def edit_path(a_var = true)
      nested? ? "edit_#{nesting_owner}_#{singular_name}_path(@#{nesting_owner}, #{a_eval(a_var)}#{singular_name})" : "edit_#{singular_name}_path(#{a_eval(a_var)}#{singular_name})"
    end
  
    def edit_form_path
      nested? ? "[@#{nesting_owner}, @#{singular_name}]" : "@#{singular_name}"
    end

    def destroy_path(a_var = true)
      nested? ? "#{nesting_owner}_#{singular_name}_path(@#{nesting_owner}, #{a_eval(a_var)}#{singular_name})" : "#{a_eval(a_var)}#{singular_name}"
    end

    # AKA, --owner was given?
    def nested?
      nesting_owner.length > 0
    end

    # if --owner specified, returns class name
    def nesting_owner_class
      nesting_owner.classify
    end


### add code to application helper, only if it already exists (so each generator ran does not repeat the code again)
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

    def add_to_application_helper(helper_code)
      return if exists_in_file?('app/helpers/application_helper.rb', helper_code)
      sentinel = 'module ApplicationHelper'

      gsub_file 'app/helpers/application_helper.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
        "#{match}\n#{helper_code}\n"
      end
    end

end
