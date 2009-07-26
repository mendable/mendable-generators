require File.dirname(__FILE__) + '/../test_helper'

class UserTest < ActiveSupport::TestCase
  
  should_not_allow_mass_assignment_of :id
  
  # Validate username field as being in our correct format. 
  should_ensure_length_in_range :username, 4..50
  should_allow_values_for :username, *%w{bob33 baz09 baz0- abcdefg13098875 -fa539 48xx5fi}
  should_not_allow_values_for :username, *%w{sht aa$12 %percent ^aaa #234ff [42fa 5ffa] 1af1" yya*}
  should_not_allow_values_for :username, ' ' # Don't allow technically empty usernames where user just tried to put a space


  # Validate email field
  context "A valid user" do
    setup { Factory(:user) }
    should_validate_uniqueness_of :email, :message => "An account with this email address already exists"
    should_validate_uniqueness_of :username
  end
  should_allow_values_for :email, *%w{com org new edu es jp info co.uk org.uk}.collect{|ending|  "foo.var_1-9@baz-quux0.example.#{ending}" }
  should_allow_values_for :email, *%w{foobar@example.com foobar@example.co.uk foobar@mail.example.com foo_bar@example.com}
  should_not_allow_values_for :email, %w{foobar@example.c @example.com @fcom foo@bar..com foobar@example.infod foobar.example.com foo@ex(ample.com foo@example,com}

  # Confirm password enforces a reasonable length constraint
  should_ensure_length_in_range :password, 4..16

end
