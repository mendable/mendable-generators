# -*- coding: mule-utf-8 -*-
module MendableAuth
  module Model
    # Stuff directives into including module 
    def self.included(recipient)
      recipient.extend(ModelClassMethods)
      recipient.class_eval do
        include ModelInstanceMethods
      end
    end

    #
    # Class Methods
    #
    module ModelClassMethods
      # Authenticates a user. Pass an email address and password to authenticate.
      # Function returns the corresponding user record if valid, or nil.
      def authenticate(email, auth_password = "")
        attempted_user = find_by_email(email)
        if attempted_user and BCrypt::Password.new(attempted_user.crypted_password) == auth_password.downcase then
          attempted_user
        else
          nil
        end
      end

      def secure_digest(*args)
        Digest::SHA1.hexdigest(args.flatten.join('--'))
      end

      def make_token
        secure_digest(Time.now, (1..10).map{ rand.to_s })
      end
    end # class methods

    #
    # Instance Methods
    #
    module ModelInstanceMethods

      protected
        # Send user an email after signup. This should be called as an after_save hook.
        def deliver_signup_email
          Email.deliver_signup(self)
        end

        # update the crypted_password field if the user enters a new password.
        # This should be called as a before_save hook.
        def encrypt_password
          return if password.blank?
          self.crypted_password = BCrypt::Password.create(password.downcase)
        end

        def password_required?
          crypted_password.blank? || !password.blank?
        end

      public

        # Function returns a hash code that can be sent out in URL's by email, user clicks the url,
        # and we can verify the hash code they pass back in the url ties in to this user account.
        def password_reset_code
          Digest::SHA1.hexdigest(self.crypted_password)
        end

        def remember_token?
          (!remember_token.blank?) && 
            remember_token_expires_at && (Time.now.utc < remember_token_expires_at.utc)
        end

        # These create and unset the fields required for remembering users between browser closes
        def remember_me
          remember_me_for 2.weeks
        end

        def remember_me_for(time)
          remember_me_until time.from_now.utc
        end

        def remember_me_until(time)
          self.remember_token_expires_at = time
          self.remember_token            = self.class.make_token
          save(false)
        end

        # Deletes the server-side record of the authentication token.  The
        # client-side (browser cookie) and server-side (this remember_token) must
        # always be deleted together.
        def forget_me
          self.remember_token_expires_at = nil
          self.remember_token            = nil
          save(false)
        end
    end # instance methods
  end

  module Controller
    # Stuff directives into including module 
    def self.included( recipient )
      recipient.extend( ControllerClassMethods )
      recipient.class_eval do
        include ControllerInstanceMethods
      end
    end

    #
    # Class Methods
    #
    module ControllerClassMethods
    end # class methods
    
    module ControllerInstanceMethods
      # Returns the currently logged in user, otherwise nil/false.
      def current_user
        @current_user ||= (login_from_session || login_from_cookie) unless @current_user == false
      end

      # Sets the currently logged in user
      def set_current_user(user)
        session[:user_id] = user.is_a?(User) ? user.id : false
        @current_user = user
      end

      # Is the user currently logged in, or are they browsing as a guest? Returns
      # true/false accordingly.
      def logged_in?
        !!current_user
      end

      # before_filter to ensure a user is logged in before accessing specified actions.
      def login_required
        logged_in? || access_denied
      end

      # Called from #current_user.  First attempt to login by the user id stored in the session.
      def login_from_session
        self.set_current_user(User.find_by_id(session[:user_id])) if session[:user_id]
      end

      # Called from #current_user.  Finally, attempt to login by an expiring token in the cookie.
      def login_from_cookie
        user = cookies[:auth_token] && User.find_by_remember_token(cookies[:auth_token])
        if user && user.remember_token? # user found, and token is within date
          self.set_current_user(user)
          self.current_user
        end
      end

      # Refresh the cookie auth token if it exists, create it otherwise
      def handle_remember_cookie!(new_cookie_flag)
        return unless current_user
        if new_cookie_flag then
          current_user.remember_me
        else
          current_user.forget_me
        end
        send_remember_cookie!
      end

      def kill_remember_cookie!
        cookies.delete :auth_token
      end

      def send_remember_cookie!
        cookies[:auth_token] = {
          :value   => current_user.remember_token,
          :expires => current_user.remember_token_expires_at }
      end


      # This is ususally what you want; resetting the session willy-nilly wreaks
      # havoc with forgery protection, and is only strictly necessary on login.
      # However, **all session state variables should be unset here**.
      def logout_keeping_session!
        # Kill server-side auth cookie
        current_user.forget_me if current_user.is_a? User
        set_current_user(false)     # not logged in, and don't do it for me
        kill_remember_cookie!     # Kill client-side auth cookie
        session[:user_id] = nil   # keeps the session but kill our variable
        # explicitly kill any other session variables you set
      end

      # The session should only be reset at the tail end of a form POST --
      # otherwise the request forgery protection fails. It's only really necessary
      # when you cross quarantine (logged-out to logged-in).
      def logout_killing_session!
        logout_keeping_session!
        reset_session
      end


      # Redirect to the URI stored by the most recent store_location call or
      # to the passed default.  Set an appropriately modified. 
      #   after_filter :store_location, :only => [:index, :new, :show, :edit]
      # for any controller you want to be bounce-backable.
      def redirect_back_or_default(default)
        redirect_to(session[:return_to] || default)
        session[:return_to] = nil
      end

      # The default action is to redirect to the login screen.
      #
      # Override this method in your controllers if you want to have special
      # behavior in case the user is not authorized to access the requested action.
      def access_denied
        respond_to do |format|
          format.html do
            store_location
            redirect_to login_url
          end
          # format.any doesn't work in rails version < http://dev.rubyonrails.org/changeset/8987
          # Add any other API formats here.  (Some browsers, notably IE6, send Accept: */* and trigger 
          # the 'format.any' block incorrectly. See http://bit.ly/ie6_borken or http://bit.ly/ie6_borken2
          # for a workaround.)
          format.any(:json, :xml) do
            request_http_basic_authentication 'Web Password'
          end
        end
      end

      # Store the URI of the current request in the session.
      # We can return to this location by calling #redirect_back_or_default.
      def store_location(redirect_url = '')
        session[:return_to] = redirect_url || request.request_uri
      end


      def self.included(base)
        base.send :helper_method, :current_user, :logged_in? if base.respond_to? :helper_method
      end

    end # instance methods
  end
end

