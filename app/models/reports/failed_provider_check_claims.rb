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
      "Contract of employment",
      "Teaching responsibilities",
      "First 5 years of teaching",
      "One full term",
      "Timetabled teaching hours",
      "Age range taught",
      "Subject",
      "Course",
      "2.5 hours weekly teaching",
      "Performance",
      "Disciplinary"
    ]

    # Update the task name to the year two name
    # Update the body to pull the data from the new location.
    def initialize
      @claims = Claim
        .by_policy(Policies::FurtherEducationPayments)
        .approved
        .where(academic_year: AcademicYear.current)
        .joins(:tasks)
        .merge(Task.where(name: "provider_verification", passed: false))
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
          provider_answer("contract_type"),
          provider_answer("teaching_responsibilities"),
          provider_answer("further_education_teaching_start_year"),
          provider_answer("taught_at_least_one_term"),
          provider_answer("teaching_hours_per_week"),
          provider_answer("half_teaching_hours"),
          provider_answer("subjects_taught"),
          # The provider verifies the courses taught question as part of
          # verifying the subjects taught question, so these two columns will
          # always be the same.
          provider_answer("subjects_taught"),
          provider_answer("teaching_hours_per_week_next_term"),
          provider_answer("subject_to_formal_performance_action"),
          provider_answer("subject_to_disciplinary_action")
        ]
      end

      private

      attr_reader :claim

      def approval_date
        I18n.l(approval.created_at.to_date, format: :day_month_year)
      end

      def approval
        @approval ||= claim.decisions.reject(&:undone).last
      end

      def provider_answer(name)
        case claim.eligibility.verification_assertion(name)
        when true then "Yes"
        when false then "No"
        else "N/A" # fixed and variable contracts have different assertions
        end
      end
    end
  end
end
