class ActiveSupport::TestCase
  class << self
    def should_require_login(method, action, params={})
      method = method.to_s.downcase
      context "'#{method.upcase}' method on '#{action}' action" do
        setup do
          make_request(method, action, params)
        end

        should "require login" do
          assert_redirected_to login_url
        end
      end
    end

<% if options[:with_simple_admin] %>
   def should_require_admin_login(method, action, params={})
      method = method.to_s.downcase
      context "'#{method.upcase}' method on '#{action}' action" do
        context "When not logged in" do
          setup do
            session[:user_id] = nil
            make_request(method, action, params)
          end

          should "require login" do
            assert_redirected_to login_url
          end
        end
        context "When logged in as non-admin user" do
          setup do
            @user = Factory(:user)
            login_as @user
            make_request(method, action, params)
          end

          should "still require login" do
            assert_redirected_to login_url
          end
        end
      end
    end
<% end -%>
  end # Class<<Self


  def login_as(user)
    @request.session[:user_id] = user.id
  end

  def make_request(method, action, params = {})
    case method
      when "get"   : get(action, params)
      when "post"  : post(action, params)
      when "put"   : put(action, params)
      when "delete": delete(action, params)
      else raise "#{method.upcase} is an unknown HTTP method"
    end
  end

end
