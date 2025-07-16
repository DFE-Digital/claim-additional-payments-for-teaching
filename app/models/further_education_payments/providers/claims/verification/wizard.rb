module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class Wizard
          FORMS = [
            RoleAndExperienceForm,
            ContractCoversFullAcademicYearForm,
            TaughtAtLeastOneAcademicTermForm,
            PerformanceAndDisciplineForm,
            ContractedHoursForm,
            CheckAnswersForm
          ]

          def self.first_slug
            "role_and_experience"
          end

          def initialize(claim:, user:, current_slug:)
            @claim = claim
            @user = user
            @current_slug = current_slug
          end

          def current_form
            find_form(current_slug)
          end

          def next_form
            # These guards are required to support changing the role and
            # experience answers. If the contract type is non permanent, we need
            # to show the additional screen, even if no answers were changed on
            # the first screen.
            if current_slug == "role_and_experience"
              if reachable_steps.include?(ContractCoversFullAcademicYearForm)
                return find_form("contract_covers_full_academic_year")
              end

              if reachable_steps.include?(TaughtAtLeastOneAcademicTermForm)
                return find_form("taught_at_least_one_academic_term")
              end
            end

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

            @reachable_steps << RoleAndExperienceForm

            if eligibility.provider_verification_contract_type == "fixed_term"
              @reachable_steps << ContractCoversFullAcademicYearForm
            end

            if eligibility.provider_verification_contract_type == "variable_hours"
              @reachable_steps << TaughtAtLeastOneAcademicTermForm
            end

            @reachable_steps << PerformanceAndDisciplineForm

            @reachable_steps << ContractedHoursForm

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
