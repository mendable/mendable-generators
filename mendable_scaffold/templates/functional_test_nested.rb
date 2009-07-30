require File.dirname(__FILE__) + '/../test_helper'

class <%= controller_class_name %>ControllerTest < ActionController::TestCase

  context "With an existing <%= nesting_owner %>" do
    setup do
      @<%= nesting_owner %> = Factory(:<%= nesting_owner %>)
    end

    context "I want to view the new <%= file_name %> page and it" do
      setup { get :new, :<%= nesting_owner %>_id => @<%= nesting_owner %> }
      should_respond_with :success
      should_render_template :new
    end

    context "I want to create new <%= file_name %> and it" do
      setup do 
        post :create, :<%= nesting_owner %>_id => @<%= nesting_owner %>, :<%= file_name %> => Factory.attributes_for(:<%= file_name %>)
      end
      
      should_set_the_flash_to /successfully created/
      should_assign_to :<%= file_name %>
      should_redirect_to("show page") { <%= nesting_owner %>_<%= file_name %>_path(@<%= nesting_owner %>, assigns(:<%= file_name %>)) }
    end
  end


  context "With an existing <%= nesting_owner %> that has <%= file_name %>" do
    setup do
      @<%= file_name %> = Factory(:<%= file_name %>)
      @<%= nesting_owner %> = @<%= file_name %>.<%= nesting_owner %>
    end
    
    context "I want to view a list of all of my <%= table_name %> and it" do
      setup { get :index, :<%= nesting_owner %>_id => @<%= nesting_owner %> }

      should_respond_with :success
      should_render_template :index
      should_assign_to :<%= table_name %>
    end
  end


  context "With an existing <%= nesting_owner %> and <%= file_name %>" do
    setup do
      @<%= file_name %> = Factory(:<%= file_name %>)
      @<%= nesting_owner %> = @<%= file_name %>.<%= nesting_owner %>
    end

    context "I want to see the edit page and it" do
      setup { get :edit, :<%= nesting_owner %>_id => @<%= nesting_owner %>, :id => @<%= file_name %> }
      should_respond_with :success
      should_render_template :edit
    end

    context "I want to update the <%= file_name %> and it" do
      setup { put :update, :<%= nesting_owner %>_id => @<%= nesting_owner %>, :id => @<%= file_name %>, :<%= file_name %> => {} } 
      should_set_the_flash_to /successfully updated/
      should_redirect_to("show page") { <%= nesting_owner %>_<%= file_name %>_path(@<%= nesting_owner %>, assigns(:<%= file_name %>)) }
    end
  end
 
end
