# frozen_string_literal: true

module SimplePolicyPayments
  class EligibilityAnswersPresenter
    include ActionView::Helpers::TranslationHelper

    attr_reader :eligibility

    def initialize(eligibility)
      @eligibility = eligibility
    end

    def answers = []
  end
end
