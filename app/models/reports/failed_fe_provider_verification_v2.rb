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
      "Contract of employment",
      "Teaching responsibilities",
      "One full term",
      "Timetabled teaching hours",
      "Half teaching hours",
      "Half timetabled teaching time",
      "Performance",
      "Disciplinary",
      "Bank details match",
      "Date of birth",
      "Email",
      "Employed by college",
      "National Insurance number",
      "Postcode",
      "Continued employment",
      "Contract covers full academic year",
      "Teaching qualification",
      "Not started qualification reasons",
      "Not started qualification other reason",
      "Employment declaration",
      "Declaration",
      "Provider verification started at",
      "Provider verification completed at"
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
          claim.eligibility.provider_verification_contract_type,
          boolean(claim.eligibility.provider_verification_teaching_responsibilities),
          boolean(claim.eligibility.provider_verification_taught_at_least_one_academic_term),
          claim.eligibility.provider_verification_teaching_hours_per_week,
          boolean(claim.eligibility.provider_verification_half_teaching_hours),
          boolean(claim.eligibility.provider_verification_half_timetabled_teaching_time),
          boolean(claim.eligibility.provider_verification_performance_measures),
          boolean(claim.eligibility.provider_verification_disciplinary_action),
          boolean(claim.eligibility.provider_verification_claimant_bank_details_match),
          format_date(claim.eligibility.provider_verification_claimant_date_of_birth),
          claim.eligibility.provider_verification_claimant_email,
          boolean(claim.eligibility.provider_verification_claimant_employed_by_college),
          claim.eligibility.provider_verification_claimant_national_insurance_number,
          claim.eligibility.provider_verification_claimant_postcode,
          boolean(claim.eligibility.provider_verification_continued_employment),
          boolean(claim.eligibility.provider_verification_contract_covers_full_academic_year),
          claim.eligibility.provider_verification_teaching_qualification,
          claim.eligibility.provider_verification_not_started_qualification_reasons,
          claim.eligibility.provider_verification_not_started_qualification_reason_other,
          boolean(claim.eligibility.provider_verification_claimant_employment_check_declaration),
          boolean(claim.eligibility.provider_verification_declaration),
          format_time(claim.eligibility.provider_verification_started_at),
          format_time(claim.eligibility.provider_verification_completed_at)
        ]
      end

      def decision
        @decision ||= claim.decisions.active.last
      end

      def format_date(date)
        return unless date

        I18n.l(date, format: :day_month_year)
      end

      def format_time(time)
        return unless time

        I18n.l(time)
      end

      def decision_date
        return unless decision

        I18n.l(decision.created_at.to_date, format: :day_month_year)
      end

      def decision_agent
        return unless decision

        decision.created_by&.full_name
      end

      def boolean(value)
        case value
        when true
          "Yes"
        when false
          "No"
        when nil
          nil
        else
          value
        end
      end
    end
  end
end
