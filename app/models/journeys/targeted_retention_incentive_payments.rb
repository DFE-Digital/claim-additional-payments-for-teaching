module Journeys
  module TargetedRetentionIncentivePayments
    extend Base
    extend self

    ROUTING_NAME = "targeted-retention-incentive-payments"
    VIEW_PATH = "targeted_retention_incentive_payments"
    I18N_NAMESPACE = "targeted_retention_incentive_payments"
    POLICIES = [Policies::TargetedRetentionIncentivePayments]
    FORMS = {
      "claims" => {
        "nqt-in-academic-year-after-itt" => NqtInAcademicYearAfterIttForm,
        "supply-teacher" => SupplyTeacherForm,
        "poor-performance" => PoorPerformanceForm,
        "qualification" => QualificationForm,
        "itt-year" => IttAcademicYearForm,
      }
    }

    def self.use_navigator?
      true
    end
  end
end
