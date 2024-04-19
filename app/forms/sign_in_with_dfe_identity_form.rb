class SignInWithDfeIdentityForm < Form
  def save!
    # Handles user somehow using Back button to go back and choose "Continue
    # with DfE Identity" option. Or they sign in a second time,
    # `details_check` needs resetting in case details are different.
    claim.assign_attributes(details_check: nil, logged_in_with_tid: true)

    if has_teacher_id_user_info?
      claim.assign_attributes(teacher_id_user_info: teacher_id_user_info)
    end

    claim.save!
  end

  private

  def teacher_id_user_info
    @teacher_id_user_info ||= params[:teacher_id_user_info]
  end

  def has_teacher_id_user_info?
    teacher_id_user_info.dig(:trn).present?
  end
end
