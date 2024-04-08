# frozen_string_literal: true

class InductionCompletedForm < Form
  attribute :induction_completed

  validates :induction_completed, presence: { message: lambda { |object, _data|
                                                         object.i18n_errors_path('select_yes_if_completed')
                                                       } }

  def initialize(claim:, journey:, params:)
    super

    self.induction_completed = permitted_params.fetch(:induction_completed, claim.eligibility.induction_completed)
  end

  def save
    return false unless valid?

    update!({ 'eligibility_attributes' => { 'induction_completed' => induction_completed } })
  end

  private

  def i18n_form_namespace
    'induction_completed'
  end

  def permitted_params
    @permitted_params ||= params.fetch(:claim, {}).permit(:induction_completed)
  end
end
