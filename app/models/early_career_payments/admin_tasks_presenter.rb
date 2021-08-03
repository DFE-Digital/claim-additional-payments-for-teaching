module EarlyCareerPayments
  # Used to display the information a claim checker needs to check to either
  # approve or reject a claim.
  class AdminTasksPresenter
    include Admin::PresenterMethods

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
end
