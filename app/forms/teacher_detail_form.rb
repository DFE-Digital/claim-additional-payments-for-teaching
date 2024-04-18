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
      ApplicationRecord.transaction do
        claim.update!(details_check: true)
        DfeIdentity::ClaimUserDetailsUpdater.call(claim)
      end

      # Reset by ClaimUserDetailsUpdater
      # FIXME inline all this into this form
      if claim.reload.details_check?
        Dqt::RetrieveClaimQualificationsData.call(claim)
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
