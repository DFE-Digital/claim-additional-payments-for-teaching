require "csv"

module Reports
  class FailedFeProviderVerificationV2
    NAME = "FE Claims with failed provider check"

    HEADERS = [
      "Claim reference",
      "Full name",
      "Claim amount",
      "Claim status",
      "Decision date",
      "Decision agent",
      "Failure reasons",
      "Not started qualification reasons",
      "Not started qualification other reason"
    ]

    def to_csv
      CSV.generate(
        row_sep: "\r\n",
        write_headers: true,
        headers: HEADERS
      ) do |csv|
        claims.each do |claim|
          csv << ClaimPresenter.new(claim).to_a
        end
      end
    end

    private

    def claims
      @claims ||= Claim
        .approved
        .by_policy(Policies::FurtherEducationPayments)
        .where(academic_year:)
        .joins(:tasks)
        .merge(failed_provider_tasks)
        .includes(:eligibility, decisions: :created_by)
    end

    def failed_provider_tasks
      Task
        .where(name: "fe_provider_verification_v2")
        .failed
    end

    def academic_year
      AcademicYear.new("2025/2026")
    end

    class ClaimPresenter
      include Admin::ClaimsHelper
      include ActionView::Helpers::NumberHelper

      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      def to_a
        [
          claim.reference,
          claim.full_name,
          number_to_currency(claim.award_amount, precision: 0),
          status(claim),
          decision_date,
          decision_agent,
          failure_reasons,
          claim.eligibility.provider_verification_not_started_qualification_reasons,
          claim.eligibility.provider_verification_not_started_qualification_reason_other
        ]
      end

      private

      def failure_reasons
        return if task.nil?

        reasons = (task.data || {}).fetch("failed_checks", [])
        reasons.join(",")
      end

      def task
        @task ||= claim
          .tasks
          .find_by(
            name: AutomatedChecks::ClaimVerifiers::FeProviderVerificationV2::TASK_NAME
          )
      end

      def decision
        @decision ||= claim.decisions.active.last
      end

      def decision_date
        return unless decision

        I18n.l(decision.created_at.to_date, format: :day_month_year)
      end

      def decision_agent
        return unless decision

        decision.created_by&.full_name
      end
    end
  end
end
