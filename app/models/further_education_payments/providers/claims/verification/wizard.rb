module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class Wizard
          FORMS = [
            RoleAndExperienceForm,
            ContractCoversFullAcademicYearForm,
            TaughtAtLeastOneAcademicTermForm,
            CheckAnswersForm
          ]

          def initialize(claim:, user:)
            @claim = claim
            @user = user
          end

          def current_form
            reachable_forms.detect(&:incomplete?)
          end

          def clear_impermissible_answers!
            ApplicationRecord.transaction do
              unreachable_forms.each(&:clear_answers!)
            end
          end

          private

          attr_reader :claim, :user, :forms

          delegate :eligibility, to: :claim

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

            @reachable_steps << CheckAnswersForm

            @reachable_steps
          end

          def unreachable_steps
            FORMS - reachable_steps
          end

          def build_forms(form_classes)
            form_classes.map do |form_class|
              form_class.new(
                claim: claim,
                user: user,
                params: claim.eligibility.attributes.slice(
                  *form_class.attribute_names.map(&:to_s)
                )
              )
            end
          end
        end
      end
    end
  end
end
