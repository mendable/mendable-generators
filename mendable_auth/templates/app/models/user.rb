class User < ActiveRecord::Base

  VALID_EMAIL_REGEX = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,4})$/i
  VALID_USERNAME_REGEX = /^[a-z0-9\-]*$/i

  attr_protected :id
  
  validates_presence_of :username
  validates_uniqueness_of :username
  validates_format_of :username, :with => VALID_USERNAME_REGEX, :message => "Username can only contain letters a-z, numbers and dashes"
  validates_length_of :username, :in => 4..50

  validates_presence_of :password
  validates_length_of :password, :in => 4..16

  validates_presence_of :email
  validates_uniqueness_of :email, :message => "An account with this email address already exists"
  validates_format_of :email, :with => VALID_EMAIL_REGEX, :message => "Address does not appear to be a valid email address"

end
