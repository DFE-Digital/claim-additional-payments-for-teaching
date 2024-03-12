# frozen_string_literal: true

module Journeys
  module AdditionalPaymentsForTeaching
    ROUTING_NAME = "additional-payments"
    VIEW_PATH = "additional_payments"
    I8N_NAMESPACE = "additional_payments"
    POLICIES = [Policies::EarlyCareerPayments, LevellingUpPremiumPayments]
  end
end
