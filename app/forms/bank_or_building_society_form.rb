class BankOrBuildingSocietyForm < Form
  attribute :bank_or_building_society

  validates :bank_or_building_society,
    inclusion: {
      in: Claim.bank_or_building_societies.keys,
      message: i18n_error_message(:select_bank_or_building_society)
    }

  def save
    return false unless valid?

    if bank_or_building_society_changed?
      journey_session.answers.assign_attributes(
        banking_name: nil,
        bank_account_number: nil,
        bank_sort_code: nil,
        building_society_roll_number: nil
      )
    end

    journey_session.answers.assign_attributes(bank_or_building_society:)

    journey_session.save!
  end

  def radio_options
    [
      OpenStruct.new(id: :personal_bank_account, name: "Personal bank account"),
      OpenStruct.new(id: :building_society, name: "Building society")
    ]
  end

  private

  def bank_or_building_society_changed?
    answers.bank_or_building_society != bank_or_building_society
  end
end
