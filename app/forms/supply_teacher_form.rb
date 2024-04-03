class SupplyTeacherForm < Form
  attribute :employed_as_supply_teacher

  # TODO validations

  def initialize(claim:, journey:, params:)
    super

    self.employed_as_supply_teacher = permitted_params[:eligibility_attributes]
  end

  def save
    return false unless valid?

    update!({ eligibility_attributes: employed_as_supply_teacher })
  end

  private

  def i18n_form_namespace
    "supply_teacher"
  end

  def permitted_params
    @permitted_params ||= params.fetch(:claim, {}).permit(eligibility_attributes: [:employed_as_supply_teacher])
  end
end
