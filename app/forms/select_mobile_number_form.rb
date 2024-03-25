class SelectMobileNumberForm
  def self.extract_attributes(claim, mobile_check:)
    new(claim, mobile_check).extract_attributes
  end

  def initialize(claim, mobile_check)
    @claim = claim
    @mobile_check = mobile_check
  end

  def extract_attributes
    case @mobile_check
    when "use"
      {
        mobile_number: @claim.teacher_id_user_info["phone_number"],
        provide_mobile_number: true,
        mobile_check: @mobile_check,
        mobile_verified: nil
      }
    when "alternative"
      {
        mobile_number: nil,
        provide_mobile_number: true,
        mobile_check: @mobile_check,
        mobile_verified: nil
      }
    when "declined"
      {
        mobile_number: nil,
        provide_mobile_number: false,
        mobile_check: @mobile_check,
        mobile_verified: nil
      }
    end
  end
end
