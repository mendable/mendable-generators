Factory.define :user do |u|
  u.sequence(:username) { |n| "username-#{n}" }
  u.crypted_password "$2a$10$zQp.4GDfZCaeiGFXCapw.OsQ6z060I6KAh5GIaqSaW0hitenxU.1S"
  u.sequence(:email) { |n| "foobar-#{n}@example.com" }
end
