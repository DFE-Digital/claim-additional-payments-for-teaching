class TeacherDetailForm < Form
  attribute :details_check, :boolean

  validates :details_check,
    inclusion: {
      in: [true, false],
      message: ->(form, _) { form.i18n_errors_path(:details_check) }
    }

  def given_name
    claim.teacher_id_user_info["given_name"]
  end

  def family_name
    claim.teacher_id_user_info["family_name"]
  end

  def birthdate
    Date.parse(claim.teacher_id_user_info["birthdate"])
  rescue ArgumentError, TypeError
    nil
  end

  def trn
    claim.teacher_id_user_info["trn"]
  end

  def national_insurance_number
    claim.teacher_id_user_info["ni_number"]
  end

  def save
    return false unless valid?

    if details_check
      if DfeIdentity::UserInfo.validated?(claim.teacher_id_user_info)
        claim.update!(
          first_name: claim.teacher_id_user_info["given_name"],
          surname: claim.teacher_id_user_info["family_name"],
          teacher_reference_number: claim.teacher_id_user_info["trn"],
          date_of_birth: claim.teacher_id_user_info["birthdate"],
          national_insurance_number: claim.teacher_id_user_info["ni_number"],
          logged_in_with_tid: true,
          dqt_teacher_status: nil,
          details_check: true
        )

        Dqt::RetrieveClaimQualificationsData.call(claim)
      else
        claim.update!(
          logged_in_with_tid: true,
          details_check: false,
          dqt_teacher_status: nil
        )
      end
    else
      claim.update!(
        first_name: "",
        surname: "",
        teacher_reference_number: "",
        date_of_birth: nil,
        national_insurance_number: "",
        logged_in_with_tid: false,
        details_check: false
      )
    end

    true
  end
end
