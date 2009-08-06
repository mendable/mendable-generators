class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %> do |t|
      t.string :username
      t.string :email
      t.string :crypted_password
      t.string :remember_token
      t.datetime :remember_token_expires_at
      <% if options[:with_simple_admin] %>
      t.boolean :is_admin
      <% end -%>
      t.timestamps
    end

    add_index :<%= table_name %>, :email, :unique => true
  end
 
  def self.down
    drop_table :<%= table_name %>
  end
end
