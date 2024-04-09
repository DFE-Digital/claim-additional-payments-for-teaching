# frozen_string_literal: true

module Journeys
  module AdditionalPaymentsForTeaching
    extend Base
    extend self

    ROUTING_NAME = "additional-payments"
    VIEW_PATH = "additional_payments"
    I18N_NAMESPACE = "additional_payments"
    POLICIES = [Policies::EarlyCareerPayments, Policies::LevellingUpPremiumPayments]
    FORMS = {
      "nqt-in-academic-year-after-itt" => NqtInAcademicYearAfterIttForm,
      "supply-teacher" => SupplyTeacherForm,
      "poor-performance" => PoorPerformanceForm
    }.freeze
  end
end
