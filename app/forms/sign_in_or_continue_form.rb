class SignInOrContinueForm < Form
  # Sub form for handling nested attributes with `fields_for`
  class TeacherIdUserInfoForm
    include ActiveModel::Model
    include ActiveModel::Attributes

    DFE_IDENTITY_ATTRIBUTES = %i[
      given_name
      family_name
      trn
      birthdate
      ni_number
      trn_match_ni_number
      email
      email_verified
      phone_number
    ]

    DFE_IDENTITY_ATTRIBUTES.each do |attribute_name|
      attribute attribute_name
    end

    def safe_birthdate
      Date.parse(birthdate)
    rescue ArgumentError, TypeError
      nil
    end
  end

  attribute :logged_in_with_tid, :boolean, default: false
  attribute :details_check, :boolean
  attribute :teacher_id_user_info_attributes

  validates :details_check,
    inclusion: {
      in: ->(form) { form.radio_options.map(&:id) },
      message: ->(form, _) { form.i18n_errors_path(:details_check) }
    }, if: :signed_in_with_dfe_identity?

  def teacher_id_user_info_attributes=(attributes)
    teacher_id_user_info.assign_attributes(
      attributes || journey_session.answers.teacher_id_user_info
    )
  end

  def teacher_id_user_info
    @teacher_id_user_info ||= TeacherIdUserInfoForm.new
  end

  # See omnioauth_callbacks_controller.rb
  def signed_in_with_dfe_identity?
    logged_in_with_tid
  end

  def save
    return false unless valid?

    if signed_in_with_dfe_identity?
      update_from_dfe_identity_sign_in!
    else
      update_from_skipped_dfe_identity_sign_in!
    end

    true
  end

  def tid_bypassable?
    Rails.env.development?
  end

  def radio_options
    [
      Option.new(id: true, name: "Yes"),
      Option.new(id: false, name: "No")
    ]
  end

  private

  def permitted_attributes
    super + [
      teacher_id_user_info_attributes: TeacherIdUserInfoForm::DFE_IDENTITY_ATTRIBUTES
    ]
  end

  def update_from_dfe_identity_sign_in!
    if details_check
      if DfeIdentity::UserInfo.validated?(teacher_id_user_info.attributes)
        journey_session.answers.assign_attributes(
          first_name: teacher_id_user_info.given_name,
          surname: teacher_id_user_info.family_name,
          teacher_reference_number: teacher_id_user_info.trn,
          date_of_birth: teacher_id_user_info.birthdate,
          national_insurance_number: teacher_id_user_info.ni_number,
          logged_in_with_tid: true,
          dqt_teacher_status: nil,
          details_check: true,
          teacher_id_user_info: teacher_id_user_info.attributes
        )

        journey_session.save!

        Dqt::RetrieveClaimQualificationsData.call(journey_session)
      else
        journey_session.answers.assign_attributes(
          logged_in_with_tid: true,
          details_check: false,
          dqt_teacher_status: nil,
          teacher_id_user_info: teacher_id_user_info.attributes
        )

        journey_session.save!
      end
    else
      journey_session.answers.assign_attributes(
        first_name: "",
        surname: "",
        teacher_reference_number: "",
        date_of_birth: nil,
        national_insurance_number: "",
        logged_in_with_tid: false,
        details_check: false,
        teacher_id_user_info: teacher_id_user_info.attributes
      )

      journey_session.save!
    end
  end

  def update_from_skipped_dfe_identity_sign_in!
    journey_session.answers.assign_attributes(
      first_name: "",
      surname: "",
      teacher_reference_number: "",
      date_of_birth: nil,
      national_insurance_number: "",
      logged_in_with_tid: false,
      details_check: nil,
      teacher_id_user_info: {}
    )

    journey_session.save!
  end
end
