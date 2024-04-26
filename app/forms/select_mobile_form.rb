class SelectMobileForm < Form
  attribute :mobile_check

  validates :mobile_check,
    inclusion: {
      in: %w[use alternative declined],
      message: ->(form, _) { form.i18n_errors_path(:mobile_check) }
    }

  def phone_number
    claim.teacher_id_user_info["phone_number"]
  end

  def save
    return false unless valid?

    case mobile_check
    when "use"
      claim.update(
        mobile_number: phone_number,
        provide_mobile_number: true,
        mobile_check: mobile_check,
        mobile_verified: nil
      )
    when "alternative"
      claim.update(
        mobile_number: nil,
        provide_mobile_number: true,
        mobile_check: mobile_check,
        mobile_verified: nil
      )
    when "declined"
      claim.update(
        mobile_number: nil,
        provide_mobile_number: false,
        mobile_check: mobile_check,
        mobile_verified: nil
      )
    else
      fail "Invalid mobile_check: #{mobile_check}"
    end

    true
  end
end
