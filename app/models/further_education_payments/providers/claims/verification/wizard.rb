module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class Wizard
          FORMS = [
            TeachingResponsibilitiesForm,
            InFirstFiveYearsForm,
            TeachingQualificationForm,
            ContractTypeForm,
            ContractCoversFullAcademicYearForm,
            TaughtAtLeastOneAcademicTermForm,
            PerformanceAndDisciplineForm,
            TeachingHoursPerWeekForm,
            HalfTeachingHoursForm,
            SubjectsTaughtForm,
            CheckAnswersForm
          ]

          def initialize(claim:, user:, current_slug:)
            @claim = claim
            @user = user
            @current_slug = current_slug || next_form.slug
          end

          def current_form
            find_form(current_slug)
          end

          def next_form
            reachable_forms.detect(&:incomplete?)
          end

          def previous_form
            index = reachable_forms.index(current_form)

            fail "Current form #{current_slug.slug} is not reachable" if index.nil?
            fail "Current form #{current_slug.slug} is the first form" if index.zero?

            previous_form = reachable_forms[index - 1]

            fail "Previous form not found" if previous_form.nil?

            previous_form
          end

          def clear_impermissible_answers!
            ApplicationRecord.transaction do
              unreachable_forms.each(&:clear_answers!)
            end
          end

          def completable?
            build_forms(
              reachable_steps.excluding(CheckAnswersForm)
            ).none?(&:incomplete?)
          end

          def completed?
            reachable_forms.none?(&:incomplete?)
          end

          private

          attr_reader :claim, :user, :current_slug

          delegate :eligibility, to: :claim

          def find_form(slug)
            form = reachable_forms.detect { it.slug == slug }

            unless form
              raise(
                ActiveRecord::RecordNotFound,
                "Reachable form not found: #{slug}"
              )
            end

            form
          end

          def reachable_forms
            @reachable_forms ||= build_forms(reachable_steps)
          end

          def unreachable_forms
            @unreachable_forms ||= build_forms(unreachable_steps)
          end

          def reachable_steps
            return @reachable_steps if @reachable_steps

            @reachable_steps = []

            @reachable_steps << TeachingResponsibilitiesForm
            @reachable_steps << InFirstFiveYearsForm
            @reachable_steps << TeachingQualificationForm
            @reachable_steps << ContractTypeForm

            if eligibility.provider_verification_contract_type == "fixed_term"
              @reachable_steps << ContractCoversFullAcademicYearForm
            end

            if eligibility.provider_verification_contract_type == "variable_hours"
              @reachable_steps << TaughtAtLeastOneAcademicTermForm
            end

            @reachable_steps << PerformanceAndDisciplineForm

            @reachable_steps << TeachingHoursPerWeekForm
            @reachable_steps << HalfTeachingHoursForm
            @reachable_steps << SubjectsTaughtForm

            @reachable_steps << CheckAnswersForm

            @reachable_steps
          end

          def unreachable_steps
            FORMS - reachable_steps
          end

          def build_forms(form_classes)
            form_classes.map do |form_class|
              form_class.new(claim: claim, user: user)
            end
          end
        end
      end
    end
  end
end
