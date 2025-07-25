module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class CheckAnswersForm < BaseForm
          include Journeys::FurtherEducationPayments::CoursesHelper

          class IncompleteWizardError < StandardError; end

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
            :provider_verification_taught_at_least_one_academic_term,
            :provider_verification_performance_measures,
            :provider_verification_disciplinary_action,
            :provider_verification_teaching_hours_per_week,
            :provider_verification_half_teaching_hours,
            :provider_verification_subjects_taught,
            :provider_verification_actual_subjects_taught,
            :provider_verification_building_construction_courses,
            :provider_verification_chemistry_courses,
            :provider_verification_computing_courses,
            :provider_verification_early_years_courses,
            :provider_verification_engineering_manufacturing_courses,
            :provider_verification_maths_courses,
            :provider_verification_physics_courses,
            :provider_verification_half_timetabled_teaching_time,
            to: :eligibility
          )

          def contract_type
            case provider_verification_contract_type
            when "fixed_term" then "Fixed-term"
            when "variable_hours" then "Variable hours"
            when "permanent" then "Permanent"
            when "employed_by_another_organisation"
              "Employed by another organisation (for example, an agency or contractor)"
            else fail "Unknown contract type"
            end
          end

          def teaching_qualification
            TeachingQualificationForm::TEACHING_QUALIFICATION_OPTIONS
              .find { it.id == provider_verification_teaching_qualification }
              .name
          end

          def teaching_hours_per_week
            TeachingHoursPerWeekForm::TEACHING_HOURS_PER_WEEK_OPTIONS
              .find { it.id == provider_verification_teaching_hours_per_week }
              .name
          end

          def save
            return false unless valid?

            raise IncompleteWizardError unless wizard_completed?

            super
          end

          def save_and_exit?
            false
          end

          def actual_subjects_taught_sentence
            provider_verification_actual_subjects_taught.map do |subject|
              I18n.t(subject, scope: "further_education_payments.forms.actual_subjects_taught.options")
            end.to_sentence(last_word_connector: " and ")
          end

          def includes_subject_area?(subject_area)
            provider_verification_actual_subjects_taught
              .include?(subject_area.to_s)
          end

          def courses_for_subject_area(subject_area)
            courses_to_sentence(
              subject_area:,
              courses: public_send("provider_verification_#{subject_area}_courses"),
              none_text: "They do not teach any of these courses"
            )
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
