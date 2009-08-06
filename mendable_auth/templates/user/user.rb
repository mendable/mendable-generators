class User < ActiveRecord::Base

  include MendableAuth::Model

  attr_protected :id
  <% if options[:with_simple_admin] %>
  attr_protected :is_admin
  <% end -%>
  
  validates_presence_of :username
  validates_uniqueness_of :username
  validates_format_of :username, :with => MendableAuth.username_regex, :message => MendableAuth.bad_username_message
  validates_length_of :username, :in => 4..50

  attr_accessor :password
  before_save :encrypt_password
  validates_presence_of :password, :if => :password_required?
  validates_length_of :password, :in => 4..16, :if => :password_required?

  validates_presence_of :email
  validates_uniqueness_of :email, :message => "An account with this email address already exists"
  validates_format_of :email, :with => MendableAuth.email_regex, :message => MendableAuth.email_regex

  after_create :deliver_signup_email

end
