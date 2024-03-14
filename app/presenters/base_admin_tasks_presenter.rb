class BaseAdminTasksPresenter
  attr_reader :claim
  def initialize(claim)
    @claim = claim
  end

  def identity_confirmation
    [
      ["Current school", eligibility.current_school.name],
      ["Contact number", eligibility.current_school.phone_number]
    ]
  end

  private

  def eligibility
    claim.eligibility
  end
end
