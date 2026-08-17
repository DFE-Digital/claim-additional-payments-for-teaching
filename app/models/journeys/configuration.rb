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

    default_scope do
      where.not(
        routing_name: %w[
          additional-payments
          further-education-payments-provider
        ]
      )
    end

    # Use AcademicYear as custom ActiveRecord attribute type
    attribute :current_academic_year, AcademicYear::Type.new, default: -> { AcademicYear.current }
    attribute :close_at, default: -> { 1.year.from_now.in_time_zone("London") }
    attribute :automatic_approvals, :boolean, default: true

    validates :current_academic_year_before_type_cast, format: {with: AcademicYear::ACADEMIC_YEAR_REGEXP}
    validates :close_at, presence: true, if: :open_for_submissions?
    validate :close_at_in_future, if: :open_for_submissions?

    def targeted_retention_incentive_payments?
      journey == Journeys::TargetedRetentionIncentivePayments
    end

    def teacher_id_configurable?
      [
        TeacherStudentLoanReimbursement
      ].include?(journey)
    end

    def journey
      Journeys.for_routing_name(routing_name)
    end

    private

    def close_at_in_future
      return if close_at.blank?
      return if close_at > Time.current.in_time_zone("London")

      errors.add(:close_at, "must be in the future")
    end
  end
end
