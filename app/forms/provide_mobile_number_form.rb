class ProvideMobileNumberForm < Form
  attribute :provide_mobile_number, :boolean

  validates :provide_mobile_number,
    inclusion: {
      in: [true, false],
      message: "Select yes if you would like to provide your mobile number"
    },
    if: -> { claim.has_ecp_or_lupp_policy? }

  def save
    return false unless valid?

    claim.assign_attributes(provide_mobile_number:)
    claim.reset_eligibility_dependent_answers(["provide_mobile_number"])
    claim.save!
  end
end
