require "csv"
require "excel_utils"

module Reports
  class FailedProviderCheckClaims
    NAME = "Claims with failed provider check"

    HEADERS = [
      "Claim reference",
      "Full name",
      "Claim amount",
      "Claim status",
      "Decision date",
      "Decision agent",
      "Teaching responsibilities",
      "Contract of employment",
      "First 5 years of teaching",
      "One full term",
      "Timetabled teaching hours",
      "Age range taught",
      "Subject",
      "Course",
      "Continued employment",
      "Performance",
      "Disciplinary",
      "Not started qualification reason"
    ]

    def initialize
      @claims = Claim
        .by_policy(Policies::FurtherEducationPayments)
        .approved
        .where(academic_year: AcademicYear.current)
        .joins(:tasks)
        .merge(Task.where(name: "fe_provider_verification_v2", passed: false))
        .includes(:eligibility, decisions: :created_by)
    end

    def to_csv
      CSV.generate(
        row_sep: "\r\n",
        write_headers: true,
        headers: HEADERS
      ) do |csv|
        @claims.each do |claim|
          csv << ClaimPresenter.new(claim).to_a
        end
      end
    end

    private

    class ClaimPresenter
      include Admin::ClaimsHelper
      include ActionView::Helpers::NumberHelper

      def initialize(claim)
        @claim = claim
      end

      def to_a
        [
          claim.reference,
          claim.full_name,
          number_to_currency(claim.award_amount, precision: 0),
          status(claim),
          approval_date,
          approval.created_by.full_name,
          present(claim.eligibility.provider_verification_teaching_responsibilities),
          present(claim.eligibility.provider_verification_contract_type),
          present(claim.eligibility.provider_verification_teaching_start_year_matches_claim),
          present(claim.eligibility.provider_verification_taught_at_least_one_academic_term),
          present(claim.eligibility.provider_verification_teaching_hours_per_week), # Contracted hours
          present(claim.eligibility.provider_verification_half_teaching_hours), # Did they teach 16 year olds
          present(claim.eligibility.provider_verification_half_timetabled_teaching_time), # Subject area
          # The provider verifies the courses taught question as part of
          # verifying the subjects taught question, so these two columns will
          # always be the same.
          present(claim.eligibility.provider_verification_half_timetabled_teaching_time), # Subject area
          present(claim.eligibility.provider_verification_continued_employment), # Teaching until end of academic year
          present(claim.eligibility.provider_verification_performance_measures),
          present(claim.eligibility.provider_verification_disciplinary_action),
          not_started_qualification_reason
        ]
      end

      private

      attr_reader :claim

      def not_started_qualification_reason
        if claim.eligibility.provider_verification_not_started_qualification_reasons.empty?
          return "N/A"
        end

        if claim.eligibility.valid_reason_for_not_starting_qualification?
          "Valid reason"
        else
          "No valid reason"
        end
      end

      def approval_date
        I18n.l(approval.created_at.to_date, format: :day_month_year)
      end

      def approval
        @approval ||= claim.decisions.reject(&:undone).last
      end

      def present(value)
        case value
        when true then "Yes"
        when false then "No"
        when nil then "N/A"
        else value
        end
      end
    end
  end
end
