module Claims
  module ShowHelper
    def fieldset_legend_css_class_for_journey(journey)
      (journey == Journeys::AdditionalPaymentsForTeaching) ? "govuk-fieldset__legend--l" : "govuk-fieldset__legend--xl"
    end

    def label_css_class_for_journey(journey)
      (journey == Journeys::AdditionalPaymentsForTeaching) ? "govuk-label--l" : "govuk-label--xl"
    end

    def policy_name(policy)
      policy.short_name.downcase.singularize
    end

    def award_amount(amount)
      number_to_currency(amount, precision: 0)
    end
  end
end
