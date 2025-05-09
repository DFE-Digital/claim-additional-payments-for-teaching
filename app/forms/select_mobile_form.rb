class SelectMobileForm < Form
  attribute :mobile_check

  validates :mobile_check,
    inclusion: {
      in: %w[use alternative declined],
      message: ->(form, _) { form.t("select_mobile_form.errors.mobile_check") }
    }

  def phone_number
    answers.teacher_id_user_info["phone_number"]
  end

  def save
    return false unless valid?

    case mobile_check
    when "use"
      journey_session.answers.assign_attributes(
        mobile_number: phone_number,
        provide_mobile_number: true,
        mobile_check: mobile_check,
        mobile_verified: nil
      )
    when "alternative"
      journey_session.answers.assign_attributes(
        mobile_number: nil,
        provide_mobile_number: true,
        mobile_check: mobile_check,
        mobile_verified: nil
      )
    when "declined"
      journey_session.answers.assign_attributes(
        mobile_number: nil,
        provide_mobile_number: false,
        mobile_check: mobile_check,
        mobile_verified: nil
      )
    else
      fail "Invalid mobile_check: #{mobile_check}"
    end

    journey_session.save!
  end
end
