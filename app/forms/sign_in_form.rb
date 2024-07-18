class SignInForm < Form
  attribute :logged_in_with_onelogin, :boolean, default: false
  attribute :identity_confirmed_with_onelogin, :boolean, default: false
  attribute :email_address
  attribute :first_name
  attribute :surname
end
