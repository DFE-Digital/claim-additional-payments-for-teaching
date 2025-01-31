module Policies
  module TargetedRetentionIncentivePayments
    class AdminTasksPresenter
      extend Forwardable

      def initialize(claim)
        @existing_early_career_payments_admin_tasks_presenter = Policies::EarlyCareerPayments::AdminTasksPresenter.new(claim)
      end

      def_delegators :@existing_early_career_payments_admin_tasks_presenter, :employment, :identity_confirmation, :census_subjects_taught, :qualifications, :display_school, :student_loan_plan
    end
  end
end
