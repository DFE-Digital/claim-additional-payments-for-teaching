module Policies
  module FurtherEducationPayments
    class EligibilityAdminProviderAnswersPresenter
      def initialize(eligibility)
        @eligibility = eligibility
      end

      def provider_employment_check
        return unless eligibility.provider_verification_completed_at.present?
        return unless eligibility.employment_checked? || eligibility.claimant_not_employed_by_college?

        [
          claimant_employed_by_college,
          claimant_date_of_birth,
          claimant_national_insurance_number,
          claimant_bank_details_match,
          claimant_email
        ]
      end

      def provider_details
        return unless eligibility.provider_verification_completed_at.present?
        # If the claimant is not employed by the college the wizard exits early
        return if eligibility.claimant_not_employed_by_college?

        [
          teaching_responsibilities,
          in_first_five_years,
          teaching_qualification,
          not_started_qualification_reasons,
          contract_type,
          contract_covers_full_academic_year,
          taught_at_least_one_academic_term,
          performance_measures,
          disciplinary_measures,
          teaching_hours_per_week,
          half_teaching_hours,
          half_timetabled_teaching_time,
          continued_employment
        ]
      end

      private

      attr_reader :eligibility

      def claimant_employed_by_college
        [
          question(
            :provider_verification_claimant_employed_by_college,
            provider_name: eligibility.school.name,
            claimant_name: eligibility.claim.full_name
          ),
          I18n.t(
            eligibility.provider_verification_claimant_employed_by_college,
            scope: :boolean
          )
        ]
      end

      # If the proivder has flagged the claimant as not employed by the college,
      # we won't have answered any of the other questions
      def claimant_date_of_birth
        answer = if eligibility.provider_verification_claimant_date_of_birth
          I18n.l(eligibility.provider_verification_claimant_date_of_birth)
        else
          "Not answered"
        end
        [
          question(:provider_verification_claimant_date_of_birth),
          answer
        ]
      end

      def claimant_national_insurance_number
        answer = eligibility.provider_verification_claimant_national_insurance_number || "Not answered"

        [
          question(:provider_verification_claimant_national_insurance_number),
          answer
        ]
      end

      def claimant_bank_details_match
        answer = if eligibility.provider_verification_claimant_bank_details_match.nil?
          "Not answered"
        else
          I18n.t(
            eligibility.provider_verification_claimant_bank_details_match,
            scope: :boolean
          )
        end
        [
          question(
            :provider_verification_claimant_bank_details_match,
            claimant_name: eligibility.claim.full_name
          ),
          answer
        ]
      end

      def claimant_email
        [
          question(:provider_verification_claimant_email),
          eligibility.provider_verification_claimant_email.presence || "Not answered"
        ]
      end

      def teaching_responsibilities
        [
          question(
            :provider_verification_teaching_responsibilities,
            claimant_name: eligibility.claim.full_name
          ),
          I18n.t(
            eligibility.provider_verification_teaching_responsibilities,
            scope: :boolean
          )
        ]
      end

      def in_first_five_years
        claimant_academic_year = AcademicYear.new(
          eligibility.further_education_teaching_start_year
        )

        claimant_academic_year_full = I18n.t(
          "options.between_dates",
          start_year: claimant_academic_year.start_year,
          end_year: claimant_academic_year.end_year,
          scope: "further_education_payments.forms.further_education_teaching_start_year"
        )

        answer = if eligibility.provider_verification_teaching_start_year.nil?
          "Not answered"
        else
          provider_academic_year = AcademicYear.new(
            eligibility.provider_verification_teaching_start_year
          )
          I18n.t(
            "options.between_dates",
            start_year: provider_academic_year.start_year,
            end_year: provider_academic_year.end_year,
            scope: "further_education_payments.forms.further_education_teaching_start_year"
          )
        end

        [
          question(
            :provider_verification_teaching_start_year,
            claimant_name: eligibility.claim.full_name,
            claimant_further_education_teaching_start_year: claimant_academic_year_full
          ),
          answer
        ]
      end

      def teaching_qualification
        [
          question(
            :provider_verification_teaching_qualification,
            claimant_name: eligibility.claim.full_name
          ),
          option(
            :provider_verification_teaching_qualification,
            eligibility.provider_verification_teaching_qualification
          )
        ]
      end

      def not_started_qualification_reasons
        answer = if eligibility.provider_verification_not_started_qualification_reasons.blank?
          "Not answered"
        elsif eligibility.provider_verification_not_started_qualification_reasons.include?("other")
          eligibility.provider_verification_not_started_qualification_reason_other
        else
          eligibility.provider_verification_not_started_qualification_reasons.map do |reason|
            I18n.t(
              reason,
              scope: %w[
                further_education_payments
                providers
                claims
                verification
                forms
                not_started_qualification_reason
                options
              ].join(".")
            )
          end.join(", ")
        end

        [
          question(
            :provider_verification_not_started_qualification_reasons,
            claimant_name: eligibility.claim.full_name
          ),
          answer
        ]
      end

      def contract_type
        [
          question(
            :provider_verification_contract_type,
            claimant_name: eligibility.claim.full_name,
            provider_name: eligibility.school.name
          ),
          option(
            :provider_verification_contract_type,
            eligibility.provider_verification_contract_type,
            provider_name: eligibility.school.name
          )
        ]
      end

      def contract_covers_full_academic_year
        answer = if eligibility.provider_verification_contract_covers_full_academic_year.nil?
          "Not answered"
        else
          I18n.t(
            eligibility.provider_verification_contract_covers_full_academic_year,
            scope: :boolean
          )
        end

        [
          question(
            :provider_verification_contract_covers_full_academic_year,
            claimant_name: eligibility.claim.full_name,
            academic_year: eligibility.claim.academic_year.to_s(:long)
          ),
          answer
        ]
      end

      def taught_at_least_one_academic_term
        answer = if eligibility.provider_verification_taught_at_least_one_academic_term.nil?
          "Not answered"
        else
          I18n.t(
            eligibility.provider_verification_taught_at_least_one_academic_term,
            scope: :boolean
          )
        end

        [
          question(
            :provider_verification_taught_at_least_one_academic_term,
            claimant_name: eligibility.claim.full_name,
            provider_name: eligibility.school.name
          ),
          answer
        ]
      end

      def performance_measures
        [
          question(
            :provider_verification_performance_measures,
            claimant_name: eligibility.claim.full_name
          ),
          I18n.t(
            eligibility.provider_verification_performance_measures,
            scope: :boolean
          )
        ]
      end

      def disciplinary_measures
        [
          question(
            :provider_verification_disciplinary_action,
            claimant_name: eligibility.claim.full_name
          ),
          I18n.t(
            eligibility.provider_verification_disciplinary_action,
            scope: :boolean
          )
        ]
      end

      def teaching_hours_per_week
        [
          question(
            :provider_verification_teaching_hours_per_week,
            claimant_name: eligibility.claim.full_name,
            provider_name: eligibility.school.name
          ),
          option(
            :provider_verification_teaching_hours_per_week,
            eligibility.provider_verification_teaching_hours_per_week
          )
        ]
      end

      def half_teaching_hours
        [
          question(
            :provider_verification_half_teaching_hours,
            claimant_name: eligibility.claim.full_name
          ),
          I18n.t(
            eligibility.provider_verification_half_teaching_hours,
            scope: :boolean
          )
        ]
      end

      def half_timetabled_teaching_time
        [
          question(
            :provider_verification_half_timetabled_teaching_time,
            claimant_name: eligibility.claim.full_name
          ),
          I18n.t(
            eligibility.provider_verification_half_timetabled_teaching_time,
            scope: :boolean
          )
        ]
      end

      def continued_employment
        [
          question(
            :provider_verification_continued_employment,
            claimant_name: eligibility.claim.full_name,
            provider_name: eligibility.school.name
          ),
          I18n.t(
            eligibility.provider_verification_continued_employment,
            scope: :boolean
          )
        ]
      end

      def question(attr, options = {})
        I18n.t(
          form_scope(attr.to_s) + ".question",
          **options
        )
      end

      def option(attr, option_id, options = {})
        I18n.t(
          form_scope(attr.to_s) + ".options." + option_id,
          **options
        )
      end

      def form_scope(attr)
        "further_education_payments_provider.forms.verification.#{attr}"
      end
    end
  end
end
