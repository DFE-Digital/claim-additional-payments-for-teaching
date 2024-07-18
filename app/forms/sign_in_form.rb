class SignInForm < Form
  class OneloginUserInfoForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    ONELOGIN_USER_INFO_ATTRIBUTES = %i[
      email
      phone
    ]

    ONELOGIN_USER_INFO_ATTRIBUTES.each do |attribute_name|
      attribute attribute_name
    end
  end

  attribute :logged_in_with_onelogin, :boolean, default: false
  attribute :identity_confirmed_with_onelogin, :boolean, default: false
  attribute :onelogin_user_info_attributes
  attribute :first_name
  attribute :surname

  def onelogin_user_info_attributes=(attributes)
    onelogin_user_info.assign_attributes(
      attributes || journey_session.answers.onelogin_user_info # TODO: store answers in journey_session
    )
  end

  def onelogin_user_info
    @onelogin_user_info ||= OneloginUserInfoForm.new
  end

  private

  def permitted_attributes
    super + [
      onelogin_user_info_attributes: OneloginUserInfoForm::ONELOGIN_USER_INFO_ATTRIBUTES
    ]
  end
end
