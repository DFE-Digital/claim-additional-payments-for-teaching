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
      # taught assertion.
      # This presenter is for Year 1 (2024/2025) claims only.
      # Year 2+ claims should use AdminProviderVerificationYear2TaskPresenter.
      def assertions
        return @assertions if @assertions

        base_assertions = verification["assertions"].dup

        # Year 1 logic - keep original ordering with courses taught inserted
        subjects_taught_index = base_assertions.find_index do |h|
          h["name"] == "subjects_taught"
        end

        if subjects_taught_index
          base_assertions.insert(
            subjects_taught_index + 1,
            courses_taught_assertion
          )
        end

        @assertions = base_assertions
      end

      def find_assertion(assertions, name)
        assertions.find { |a| a["name"] == name }
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
        when "contract_type"
          # Show claimant's contract type answer
          contract_type_display_value(claim.eligibility.contract_type)
        when "teaching_hours_per_week"
          # Show claimant's teaching hours answer
          teaching_hours_display_value((claim.eligibility.teaching_hours_per_week == "more_than_12") ? "20_or_more_hours_per_week" : "12_to_20_hours_per_week")
        when "teaching_hours_per_week_next_term"
          # Variable hours contracts don't have claimant input for next term hours
          "Not provided"
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
        when "teaching_hours_per_week_next_term"
          # Show provider's answer for variable hours next term teaching hours
          teaching_hours_display_value(claim.eligibility.provider_verification_teaching_hours_per_week_next_term)
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
          "Fixed term"
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
