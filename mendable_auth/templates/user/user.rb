class User < ActiveRecord::Base

  VALID_EMAIL_REGEX = /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,4})$/i
  VALID_USERNAME_REGEX = /^[a-z0-9\-]*$/i

  attr_protected :id
  
  validates_presence_of :username
  validates_uniqueness_of :username
  validates_format_of :username, :with => VALID_USERNAME_REGEX, :message => "Username can only contain letters a-z, numbers and dashes"
  validates_length_of :username, :in => 4..50

  attr_accessor :password
  before_save :encrypt_password
  validates_presence_of :password, :if => :password_required?
  validates_length_of :password, :in => 4..16, :if => :password_required?

  validates_presence_of :email
  validates_uniqueness_of :email, :message => "An account with this email address already exists"
  validates_format_of :email, :with => VALID_EMAIL_REGEX, :message => "Address does not appear to be a valid email address"


  # Authenticates a user. Pass an email address and password to authenticate.
  # Function returns the corresponding user record if valid, or nil.
  def self.authenticate(email, auth_password = "")
    attempted_user = find_by_email(email)
    if attempted_user and BCrypt::Password.new(attempted_user.crypted_password) == auth_password.downcase then
      attempted_user
    else
      nil
    end
  end


  # Send user an email after signup
  def after_create
    Email.deliver_signup(self)    
  end

  # Function returns a hash code that can be sent out in URL's by email, user clicks the url,
  # and we can verify the hash code they pass back in the url ties in to this user account.
  def password_reset_code
    Digest::SHA1.hexdigest(self.crypted_password)
  end

  
  protected
    def encrypt_password
      return if password.blank?
      self.crypted_password = BCrypt::Password.create(password.downcase)
    end
  
    def password_required?
      crypted_password.blank? || !password.blank?
    end

end
