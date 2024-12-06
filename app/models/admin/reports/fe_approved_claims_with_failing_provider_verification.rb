module Admin
  module Reports
    class FeApprovedClaimsWithFailingProviderVerification
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

      def filename
        "fe_approved_claims_with_failing_provider_verification.csv"
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
          .by_policy(Policies::FurtherEducationPayments)
          .approved
          .joins(:tasks)
          .merge(Task.where(name: "provider_verification", passed: false))
          .includes(:eligibility, decisions: :created_by)
      end

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
            present_assertion("contract_type"),
            present_assertion("teaching_responsibilities"),
            present_assertion("further_education_teaching_start_year"),
            present_assertion("taught_at_least_one_term"),
            present_assertion("teaching_hours_per_week"),
            present_assertion("half_teaching_hours"),
            present_assertion("subjects_taught"),
            "??", # FIXME RL: not sure what courses should be
            present_assertion("teaching_hours_per_week_next_term"),
            present_assertion("subject_to_formal_performance_action"),
            present_assertion("subject_to_disciplinary_action")
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

        def present_assertion(name)
          case claim.eligibility.verification_assertion(name)
          when true then "Yes"
          when false then "No"
          else "N/A" # fixed and variable contracts have different assertions
          end
        end
      end
    end
  end
end
