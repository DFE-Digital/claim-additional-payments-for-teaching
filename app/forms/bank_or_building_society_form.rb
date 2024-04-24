class BankOrBuildingSocietyForm < Form
  attribute :bank_or_building_society

  validates :bank_or_building_society,
    inclusion: {
      in: Claim.bank_or_building_societies.keys,
      message: "Select if you want the money paid in to a personal bank account or building society"
    }

  def save
    return false unless valid?

    claim.assign_attributes(bank_or_building_society:)
    claim.reset_eligibility_dependent_answers(["bank_or_building_society"])
    claim.save!
  end
end
