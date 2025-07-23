module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class CheckAnswersForm < BaseForm
          class IncompleteWizardError < StandardError; end
          NOT_ANSWERED = "Not answered"

          attribute :provider_verification_declaration, :boolean

          validates :provider_verification_declaration,
            presence: {
              message: "Tick the box to confirm that the information " \
                       "provided in this form is correct to the best of " \
                       "your knowledge"
            }

          delegate(
            :provider_verification_teaching_responsibilities,
            :provider_verification_in_first_five_years,
            :provider_verification_teaching_qualification,
            :provider_verification_contract_covers_full_academic_year,
            :provider_verification_contract_type,
            :provider_verification_timetabled_teaching_hours,
            :provider_verification_taught_at_least_one_academic_term,
            :provider_verification_performance_measures,
            :provider_verification_disciplinary_action,
            :provider_verification_teaching_hours_per_week,
            :provider_verification_half_teaching_hours,
            :provider_verification_subjects_taught,
            to: :eligibility
          )

          def teaching_responsibilities
            if provider_verification_teaching_responsibilities.nil?
              NOT_ANSWERED
            else
              I18n.t(provider_verification_teaching_responsibilities, scope: :boolean)
            end
          end

          def in_first_five_years
            if provider_verification_in_first_five_years.nil?
              NOT_ANSWERED
            else
              I18n.t(provider_verification_in_first_five_years, scope: :boolean)
            end
          end

          def contract_type
            case provider_verification_contract_type
            when "fixed_term" then "Fixed-term"
            when "variable_hours" then "Variable hours"
            when "permanent" then "Permanent"
            when "employed_by_another_organisation"
              "Employed by another organisation (for example, an agency or contractor)"
            when nil then NOT_ANSWERED
            else fail "Unknown contract type"
            end
          end

          def teaching_qualification
            if provider_verification_teaching_qualification.nil?
              NOT_ANSWERED
            else
              TeachingQualificationForm::TEACHING_QUALIFICATION_OPTIONS
                .find { it.id == provider_verification_teaching_qualification }
                .name
            end
          end

          def contract_covers_full_academic_year
            if provider_verification_contract_covers_full_academic_year.nil?
              NOT_ANSWERED
            else
              I18n.t(provider_verification_contract_covers_full_academic_year, scope: :boolean)
            end
          end

          def taught_at_least_one_academic_term
            if provider_verification_taught_at_least_one_academic_term.nil?
              NOT_ANSWERED
            else
              I18n.t(provider_verification_taught_at_least_one_academic_term, scope: :boolean)
            end
          end

          def performance_measures
            if provider_verification_performance_measures.nil?
              NOT_ANSWERED
            else
              I18n.t(provider_verification_performance_measures, scope: :boolean)
            end
          end

          def disciplinary_action
            if provider_verification_disciplinary_action.nil?
              NOT_ANSWERED
            else
              I18n.t(provider_verification_disciplinary_action, scope: :boolean)
            end
          end

          def half_teaching_hours
            if provider_verification_half_teaching_hours.nil?
              NOT_ANSWERED
            else
              I18n.t(provider_verification_half_teaching_hours, scope: :boolean)
            end
          end

          def subjects_taught
            if provider_verification_subjects_taught.nil?
              NOT_ANSWERED
            else
              I18n.t(provider_verification_subjects_taught, scope: :boolean)
            end
          end

          def teaching_hours_per_week
            if provider_verification_teaching_hours_per_week.nil?
              NOT_ANSWERED
            else
              TeachingHoursPerWeekForm::TEACHING_HOURS_PER_WEEK_OPTIONS
                .find { it.id == provider_verification_teaching_hours_per_week }
                .name
            end
          end

          def save
            return false unless valid?

            raise IncompleteWizardError unless wizard_completed?

            super
          end

          def save_and_exit?
            false
          end

          def started_by
            DfeSignIn::User
              .find_by(id: claim.eligibility.provider_assigned_to_id)&.full_name
          end

          private

          def wizard_completed?
            Verification::Wizard.new(
              claim: claim,
              user: user,
              current_slug: slug
            ).completable?
          end

          def attributes_to_save
            super + %w[
              provider_verification_completed_at
              provider_verification_verified_by_id
            ]
          end

          def provider_verification_completed_at
            DateTime.current
          end

          def provider_verification_verified_by_id
            user.id
          end
        end
      end
    end
  end
end
