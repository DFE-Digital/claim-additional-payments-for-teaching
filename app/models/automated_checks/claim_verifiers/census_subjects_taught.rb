module AutomatedChecks
  module ClaimVerifiers
    class CensusSubjectsTaught
      TASK_NAME = "census_subjects_taught".freeze
      private_constant :TASK_NAME

      def initialize(
        claim:,
        admin_user: nil
      )
        self.admin_user = admin_user
        self.claim = claim
        self.school_workforce_census = SchoolWorkforceCensus.where(teacher_reference_number: claim.eligibility.teacher_reference_number)
        self.school_workforce_census_subjects = school_workforce_census
      end

      def perform
        return unless awaiting_task?(TASK_NAME)

        no_data || no_match || any_match
      end

      private

      attr_accessor :admin_user, :claim, :school_workforce_census
      attr_reader :school_workforce_census_subjects

      def awaiting_task?(task_name)
        claim.tasks.none? { |task| task.name == task_name }
      end

      def school_workforce_census_subjects=(school_workforce_census)
        return if school_workforce_census.empty?

        @school_workforce_census_subjects = school_workforce_census.map(&:subject_description_sfr)
      end

      def no_data
        return if school_workforce_census.present?

        create_task(match: nil)
      end

      def no_match
        return unless school_workforce_census.empty? || !eligible?

        create_task(match: :none)
      end

      def any_match
        return unless eligible?

        create_task(match: :any, passed: true)
      end

      def eligible?
        return false if school_workforce_census.empty?

        match_against = case claim.policy
        when Policies::EarlyCareerPayments
          early_career_payments_policy_subjects
        when Policies::LevellingUpPremiumPayments
          levelling_up_premium_payments_policy_subjects
        when Policies::StudentLoans
          student_loans_policy_subjects
        else
          return false
        end

        match_against.intersection(school_workforce_census_subjects).any?
      end

      def early_career_payments_policy_subjects
        ecp_subjects = [
          SchoolWorkforceCensus::COMMON_ELIGIBLE_SUBJECTS,
          SchoolWorkforceCensus::ECP_ELIGIBLE_SUBJECTS
        ].reduce({}, :update)

        ecp_subjects[claim.eligibility.eligible_itt_subject.to_sym]
      end

      def levelling_up_premium_payments_policy_subjects
        lup_subjects = [
          SchoolWorkforceCensus::LUP_ELIGIBLE_SUBJECTS
        ].reduce({}, :update)

        lup_subjects[claim.eligibility.eligible_itt_subject.to_sym]
      end

      def student_loans_policy_subjects
        tslr_subjects = [
          SchoolWorkforceCensus::COMMON_ELIGIBLE_SUBJECTS,
          SchoolWorkforceCensus::TSLR_ELIGIBLE_SUBJECTS
        ].reduce({}, :update)

        # tslr claims are keyed on :languages not :foreign_languages
        tslr_subjects[:languages] = tslr_subjects.delete(:foreign_languages)

        subjects_taught = claim.eligibility.subjects_taught.reduce([]) do |array, subject|
          array << subject.to_s.split("_").first.to_sym
        end

        subjects_taught.reduce([]) do |array, subject|
          array << tslr_subjects[subject]
        end.flatten
      end

      def create_task(match:, passed: nil)
        task = claim.tasks.build(
          {
            name: TASK_NAME,
            claim_verifier_match: match,
            passed: passed,
            manual: false,
            created_by: admin_user
          }
        )

        task.save!(context: :claim_verifier)

        create_note(match: match)

        task
      end

      def create_note(match:)
        body = if school_workforce_census.empty?
          "[School Workforce Census] - No data"
        else
          swc_subjects = ""
          school_workforce_census_subjects.each_with_index do |subject, idx|
            swc_subjects += "Subject #{idx + 1}: #{subject}\n"
          end

          <<~HTML
            [School Workforce Census] - #{(match == :none) ? "Ine" : "E"}ligible:
            <pre>#{swc_subjects}</pre>
          HTML
        end

        claim.notes.create!(
          {
            body: body,
            label: TASK_NAME,
            created_by: admin_user
          }
        )
      end
    end
  end
end
