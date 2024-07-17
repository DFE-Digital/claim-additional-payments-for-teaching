class SignInForm < Form
  attribute :logged_in_with_onelogin, :boolean, default: false
  attribute :email_address
end
