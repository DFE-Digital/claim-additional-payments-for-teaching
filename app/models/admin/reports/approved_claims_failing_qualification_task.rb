module Admin
  module Reports
    class ApprovedClaimsFailingQualificationTask
      HEADERS = [
        "Claim reference",
        "Teacher reference number",
        "Policy",
        "Status",
        "Decision date",
        "Decision agent",
        "Qualification",
        "ITT start year",
        "ITT subject",
        "ITT subjects",
        "ITT start date",
        "QTS award date",
        "Qualification name"
      ]

      def filename
        "approved_claims_failing_qualification_task.csv"
      end

      def to_csv
        CSV.generate(
          row_sep: "\r\n",
          write_headers: true,
          headers: HEADERS
        ) do |csv|
          rows.each { |row| csv << row }
        end
      end

      private

      def rows
        scope.map(&ClaimPresenter.method(:new)).map(&:to_a)
      end

      def scope
        Claim
          .approved
          .where(academic_year: AcademicYear.current)
          .joins(:tasks)
          .merge(Task.where(name: "qualifications", passed: false))
          .includes(:eligibility, decisions: :created_by)
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
            itt_academic_year&.to_s,
            eligible_itt_subject,
            dqt_teacher_record.itt_subjects.join(", "),
            I18n.l(dqt_teacher_record.itt_start_date, format: :day_month_year),
            I18n.l(dqt_teacher_record.qts_award_date, format: :day_month_year),
            dqt_teacher_record.qualification_name
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
          dqt_teacher_record&.itt_subjects
        end

        def itt_start_date
          dqt_teacher_record&.itt_start_date
        end

        def qts_award_date
          dqt_teacher_record&.qts_award_date
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
end
