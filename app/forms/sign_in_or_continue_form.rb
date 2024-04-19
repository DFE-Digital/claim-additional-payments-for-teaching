class SignInOrContinueForm < Form
  # - Sign in with Teacher ID does NOT save or interact with this Form and POSTs straight to Teacher ID
  # - If Teacher ID is disabled for the journey, we still mimick if a user clicked on "Continue without signing in".

  def initialize(claim:, journey:, params:)
    super
  end

  def save
    update!(
      first_name: "",
      surname: "",
      teacher_reference_number: "",
      date_of_birth: nil,
      national_insurance_number: "",
      logged_in_with_tid: false,
      details_check: nil,
      teacher_id_user_info: {}
    )

    true
  end
end
