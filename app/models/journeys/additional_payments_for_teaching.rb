# frozen_string_literal: true

module Journeys
  module AdditionalPaymentsForTeaching
    extend Base
    extend self

    ROUTING_NAME = "additional-payments"
    VIEW_PATH = "additional_payments"
    I18N_NAMESPACE = "additional_payments"
    POLICIES = [Policies::EarlyCareerPayments]
    FORMS = {
      "claims" => {}
    }.freeze

    def policies
      if FeatureFlag.enabled?(:tri_only_journey)
        [Policies::EarlyCareerPayments]
      else
        POLICIES
      end
    end
  end
end
