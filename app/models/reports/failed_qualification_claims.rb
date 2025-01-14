require "csv"
require "excel_utils"

module Reports
  class FailedQualificationClaims
    NAME = "Claims with failed qualification status"
    HEADERS = [
      "Claim reference",
      "Teacher reference number",
      "Policy",
      "Status",
      "Decision date",
      "Decision agent",
      "Applicant answers - Qualification",
      "Applicant answers - ITT start year",
      "Applicant answers - ITT subject",
      "DQT API - ITT subjects",
      "DQT API - ITT start date",
      "DQT API - QTS award date",
      "DQT API - Qualification name"
    ].freeze

    def initialize
      @claims = Claim
        .approved
        .where(academic_year: AcademicYear.current)
        .joins(:tasks).merge(Task.where(name: "qualifications", passed: false))
        .includes(:eligibility, decisions: :created_by)
    end

    def to_csv
      CSV.generate(write_headers: true, headers: HEADERS) do |csv|
        @claims.each do |claim|
          csv << ClaimPresenter.new(claim).to_a
        end
      end
    end

    class ClaimPresenter
      include Admin::ClaimsHelper

      def initialize(claim)
        @claim = claim
      end

      def to_a
        [
          claim.reference,
          claim.eligibility.teacher_reference_number,
          I18n.t("#{claim.policy.locale_key}.policy_acronym"),
          status(claim),
          I18n.l(approval.created_at.to_date, format: :day_month_year),
          approval.created_by.full_name,
          qualification,
          itt_academic_year,
          eligible_itt_subject,
          itt_subjects,
          itt_start_date,
          qts_award_date,
          qualification_name
        ]
      end

      private

      attr_reader :claim

      def approval
        @approval ||= claim.decisions.reject(&:undone).last
      end

      # StudentLoans doesn't have an eligible_itt_subject
      def eligible_itt_subject
        claim.eligibility.try(:eligible_itt_subject)
      end

      # StudentLoans doesn't have an itt_academic_year
      def itt_academic_year
        claim.eligibility.try(:itt_academic_year)
      end

      # StudentLoans doesn't have a qualification
      def qualification
        claim.eligibility.try(:qualification)
      end

      def itt_subjects
        dqt_teacher_record&.itt_subjects&.join(", ")
      end

      def itt_start_date
        date = dqt_teacher_record&.itt_start_date

        return unless date

        I18n.l(date, format: :day_month_year)
      end

      def qts_award_date
        date = dqt_teacher_record&.qts_award_date

        return unless date

        I18n.l(date, format: :day_month_year)
      end

      def qualification_name
        dqt_teacher_record&.qualification_name
      end

      def dqt_teacher_record
        @dqt_teacher_record ||= if claim.has_dqt_record?
          Dqt::Teacher.new(claim.dqt_teacher_status)
        end
      end
    end
  end
end
