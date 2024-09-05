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

      private

      def verification
        @verification ||= claim.eligibility.verification
      end

      def assertions
        verification["assertions"] + [courses_taught_assertion]
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
        assertion["outcome"] ? "Yes" : "No"
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