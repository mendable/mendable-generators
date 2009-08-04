class Email < ActionMailer::Base
 
  def signup(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
    @body[:url]  = "http://YOURSITE/login/"
  end

  # Forgot Password email contains a password-reset link they can 
  # click and it will allow the user to reset the password on their
  # account.
  def forgot_password(user)
    setup_email(user)
    subject "Password Reset"
  end


  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "ADMINEMAIL"
      @subject     = "[YOURSITE] "
      @sent_on     = Time.now
      @body[:user] = user
    end

end
