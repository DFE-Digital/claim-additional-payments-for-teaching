# frozen_string_literal: true

module SimplePolicyPayments
  class AdminTasksPresenter
    include Admin::PresenterMethods

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def qualifications = []

    def employment = []

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
end
