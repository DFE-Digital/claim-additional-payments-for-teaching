module Policies
  module FurtherEducationPayments
    class AdminProviderVerificationTaskPresenter
      class Row < Struct.new(
        :label,
        :claimant_answer,
        :provider_answer,
        keyword_init: true
      )
      end

      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      def rows
        assertions.map do |assertion|
          Row.new(
            label: label(assertion),
            claimant_answer: claimant_answer(assertion),
            provider_answer: provider_answer(assertion)
          )
        end
      end

      def admin_sent_emails
        @admin_sent_emails ||= claim.notes.by_label("provider_verification").order(created_at: :desc)
      end

      def verification_email_sent?
        claim.eligibility.awaiting_provider_verification?
      end

      def verification_email_sent_by_admin_team?
        admin_sent_emails.any?
      end

      private

      def verification
        @verification ||= claim.eligibility.verification
      end

      # See the `courses_taught_assertion` method for more information on why
      # that assertion is different to the others.
      # We need to make sure that when presenting the list of assertions to the
      # admin that the courses taught assertion is displayed after the subjects
      # taught assertion, and we need to add the teaching qualification assertion.
      def assertions
        return @assertions if @assertions

        base_assertions = verification["assertions"].dup

        # Insert courses taught after subjects taught
        subjects_taught_index = base_assertions.find_index do |h|
          h["name"] == "subjects_taught"
        end

        if subjects_taught_index
          base_assertions.insert(
            subjects_taught_index + 1,
            courses_taught_assertion
          )
        end

        # Add Year 2 specific fields
        base_assertions << teaching_qualification_assertion
        base_assertions << contract_type_assertion
        base_assertions << teaching_hours_assertion

        # Add conditional fields for fixed-term contracts
        if claim.eligibility.provider_verification_contract_type == "fixed_term"
          base_assertions << contract_covers_full_year_assertion
        end

        # Add conditional fields for variable hours contracts
        if claim.eligibility.provider_verification_contract_type == "variable_hours"
          base_assertions << teaching_hours_next_term_assertion
        end

        base_assertions << performance_measures_assertion
        base_assertions << disciplinary_action_assertion

        @assertions = base_assertions
      end

      # The provider verifies the courses taught question as part of verifying the
      # subjects taught question, however the admin UI designs require we
      # display these separately, so we construct an additional "assertion" for
      # courses taught
      def courses_taught_assertion
        subjects_taught_outcome = verification["assertions"].detect do |a|
          a["name"] == "subjects_taught"
        end.fetch("outcome")

        {
          "name" => "courses_taught",
          "outcome" => subjects_taught_outcome
        }
      end

      # Teaching qualification is stored directly on the eligibility model, not in assertions,
      # so we create a synthetic assertion for display purposes
      def teaching_qualification_assertion
        {
          "name" => "teaching_qualification",
          "outcome" => true  # We always show the teaching qualification value, not a yes/no
        }
      end

      def contract_type_assertion
        {
          "name" => "contract_type",
          "outcome" => true
        }
      end

      def teaching_hours_assertion
        {
          "name" => "teaching_hours_per_week",
          "outcome" => true
        }
      end

      def contract_covers_full_year_assertion
        {
          "name" => "contract_covers_full_academic_year",
          "outcome" => true
        }
      end

      def teaching_hours_next_term_assertion
        {
          "name" => "teaching_hours_per_week_next_term",
          "outcome" => true
        }
      end

      def performance_measures_assertion
        {
          "name" => "performance_measures",
          "outcome" => true
        }
      end

      def disciplinary_action_assertion
        {
          "name" => "disciplinary_action",
          "outcome" => true
        }
      end

      def label(assertion)
        I18n.t(
          [
            "further_education_payments",
            "admin",
            "task_questions",
            "provider_verification",
            assertion["name"],
            "label"
          ].join(".")
        )
      end

      def claimant_answer(assertion)
        key = assertion["name"]
        case key
        when "subjects_taught"
          subjects_taught
        when "courses_taught"
          courses_taught
        when "further_education_teaching_start_year"
          "September #{further_education_teaching_start_year.to_i} " \
            "to August #{further_education_teaching_start_year.to_i + 1}"
        when "teaching_qualification"
          # Show claimant's teaching qualification answer
          claimant_teaching_qualification = claim.eligibility.teaching_qualification
          case claimant_teaching_qualification
          when "yes"
            "Yes"
          when "not_yet"
            "Not yet, I am currently enrolled on one and working towards completing it"
          when "no_but_planned"
            "No, but I plan to enrol on one in the next 12 months"
          when "no_not_planned"
            "No, and I do not plan to enrol on one in the next 12 months"
          else
            claimant_teaching_qualification&.humanize || "Not provided"
          end
        when "in_first_five_years"
          # Map to the actual eligibility field - this doesn't have a claimant answer
          # Return a calculated value based on their start year
          in_first_five = claim.eligibility.further_education_teaching_start_year.to_i >= (AcademicYear.current.start_year - 5)
          in_first_five ? "Yes" : "No"
        when "contract_type"
          # Show claimant's contract type answer
          contract_type_display_value(claim.eligibility.contract_type)
        when "teaching_hours_per_week"
          # Show claimant's teaching hours answer
          teaching_hours_display_value((claim.eligibility.teaching_hours_per_week == "more_than_12") ? "20_or_more_hours_per_week" : "12_to_20_hours_per_week")
        when "contract_covers_full_academic_year"
          # Show claimant's answer for fixed-term contract full year coverage
          value = claim.eligibility.fixed_term_full_year
          value ? "Yes" : "No"
        when "teaching_hours_per_week_next_term"
          # Variable hours contracts don't have claimant input for next term hours
          "Not provided"
        when "performance_measures"
          # Map to the actual eligibility field
          value = claim.eligibility.subject_to_formal_performance_action
          value ? "Yes" : "No"
        when "disciplinary_action"
          # Map to the actual eligibility field
          value = claim.eligibility.subject_to_disciplinary_action
          value ? "Yes" : "No"
        else
          I18n.t(
            [
              "further_education_payments",
              "admin",
              "task_questions",
              "provider_verification",
              key,
              "claimant_answers",
              claim.eligibility.send(key)
            ].join(".")
          )
        end
      end

      def provider_answer(assertion)
        key = assertion["name"]
        case key
        when "contract_type"
          # Show actual contract type instead of Yes/No
          contract_type_display_value(claim.eligibility.provider_verification_contract_type)
        when "teaching_hours_per_week"
          # Show actual teaching hours instead of Yes/No
          teaching_hours_display_value(claim.eligibility.provider_verification_teaching_hours_per_week)
        when "contract_covers_full_academic_year"
          # Show provider's answer for fixed-term contract full year coverage
          value = claim.eligibility.provider_verification_contract_covers_full_academic_year
          value ? "Yes" : "No"
        when "teaching_hours_per_week_next_term"
          # Show provider's answer for variable hours next term teaching hours
          teaching_hours_display_value(claim.eligibility.provider_verification_teaching_hours_per_week_next_term)
        when "teaching_qualification"
          # Show actual teaching qualification instead of Yes/No
          teaching_qualification_display_value(claim.eligibility.provider_verification_teaching_qualification)
        when "performance_measures", "disciplinary_action"
          # Show inverted logic for performance/disciplinary (Yes means subject to, No means not subject to)
          provider_performance_disciplinary_answer(key)
        else
          assertion["outcome"] ? "Yes" : "No"
        end
      end

      private

      def contract_type_display_value(contract_type)
        case contract_type
        when "permanent"
          "Permanent"
        when "fixed_term"
          "Fixed-term"
        when "variable_hours"
          "Variable hours"
        when "employed_by_another_organisation"
          "Employed by another organisation (for example, an agency or contractor)"
        else
          contract_type&.humanize || "Not provided"
        end
      end

      def teaching_hours_display_value(hours)
        case hours
        when "20_or_more_hours_per_week"
          "20 hours or more each week"
        when "12_to_20_hours_per_week"
          "12 hours to 20 hours each week"
        when "2_and_a_half_to_12_hours_per_week"
          "2.5 to 12 hours each week"
        when "fewer_than_2_and_a_half_hours_per_week"
          "Fewer than 2.5 hours each week"
        else
          hours&.humanize || "Not provided"
        end
      end

      def teaching_qualification_display_value(qualification)
        case qualification
        when "yes"
          "Yes"
        when "not_yet"
          "Not yet, I am currently enrolled on one and working towards completing it"
        when "no_but_planned"
          "No, but I plan to enrol on one in the next 12 months"
        when "no_not_planned"
          "No, and I do not plan to enrol on one in the next 12 months"
        else
          qualification&.humanize || "Not provided"
        end
      end

      def provider_performance_disciplinary_answer(field)
        eligibility = claim.eligibility
        case field
        when "performance_measures"
          # Provider field is "subject to performance measures" - show Yes if true, No if false
          eligibility.provider_verification_performance_measures ? "Yes" : "No"
        when "disciplinary_action"
          # Provider field is "subject to disciplinary action" - show Yes if true, No if false
          eligibility.provider_verification_disciplinary_action ? "Yes" : "No"
        end
      end

      def subjects_taught
        claim.eligibility.subjects_taught.map do |subject|
          I18n.t(
            [
              "further_education_payments",
              "forms",
              "subjects_taught",
              "options",
              subject
            ].join(".")
          )
        end
      end

      def courses_taught
        claim.eligibility.courses_taught.map(&:description)
      end

      def further_education_teaching_start_year
        claim.eligibility.further_education_teaching_start_year
      end
    end
  end
end
