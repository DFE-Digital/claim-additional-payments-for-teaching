class SelectEmailForm
  def self.extract_attributes(claim, email_address_check:)
    new(claim, email_address_check).extract_attributes
  end

  def initialize(claim, email_address_check)
    @claim = claim
    @email_address_check = email_address_check
  end

  def extract_attributes
    if @email_address_check == "true"
      {
        email_address: @claim.teacher_id_user_info["email"],
        email_verified: true,
        email_address_check: true
      }
    else
      {
        email_address: nil,
        email_verified: nil,
        email_address_check: false
      }
    end
  end
end
