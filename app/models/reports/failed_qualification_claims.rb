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
        .joins(:tasks).merge(
          Task.qualifications.where(passed: false).or(
            Task.qualifications.claim_verifier_match_none
          )
        )
        .includes(:eligibility, :notes, decisions: :created_by)
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
          parse_note("ITT subjects"),
          parse_note("ITT start date"),
          parse_note("QTS award date"),
          parse_note("Qualification name")
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

      # dqt information isn't stored on any claims on production.
      # We don't want to make an API call for each claim in this report, so
      # instead we parse the note to get the information for the report.
      def parse_note(label)
        return unless dqt_note

        match = dqt_note.body.match(/#{label}: (.*)/)
        match ? match[1].strip : nil
      end

      def dqt_note
        @dqt_note ||= claim.notes.find_by(label: "qualifications")
      end
    end
  end
end
