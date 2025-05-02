# Journey-specific configuration, managed through the service operator's admin
# interface.
#
# Things that are currently configurable:
#
# * open_for_submissions: defines whether the journey is currently accepting
#   claims or not
# * availability_message: an optional message that is shown to users when the
#   journey is closed for submissions
# * current_academic_year: the academic year the service is currently accepting
#   claims for.
module Journeys
  class Configuration < ApplicationRecord
    self.table_name = "journey_configurations"

    # Use AcademicYear as custom ActiveRecord attribute type
    attribute :current_academic_year, AcademicYear::Type.new

    validates :current_academic_year_before_type_cast, format: {with: AcademicYear::ACADEMIC_YEAR_REGEXP}

    def targeted_retention_incentive_payments?
      journey == Journeys::TargetedRetentionIncentivePayments
    end

    def targeted_retention_incentive_payments?
      journey == Journeys::TargetedRetentionIncentivePayments
    end

    def teacher_id_configurable?
      [
        AdditionalPaymentsForTeaching,
        TeacherStudentLoanReimbursement
      ].include?(journey)
    end

    def journey
      Journeys.for_routing_name(routing_name)
    end
  end
end
