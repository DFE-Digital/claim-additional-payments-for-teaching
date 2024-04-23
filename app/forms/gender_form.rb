class GenderForm < Form
  attribute :payroll_gender

  validates :payroll_gender,
    inclusion: {
      in: Claim.payroll_genders.keys,
      message: ->(object, _) { object.i18n_errors_path("select_gender") }
    }

  def save
    return false unless valid?

    update! payroll_gender:
  end
end
