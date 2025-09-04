module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class Wizard
          FORMS = [
            ClaimantEmploymentCheckNeededForm,
            ClaimantEmployedByCollegeForm,
            ClaimantPersonalDetailsForm,
            ClaimantEmploymentCheckDeclarationForm,
            ContinueVerificationForm,
            TeachingResponsibilitiesForm,
            InFirstFiveYearsForm,
            TeachingQualificationForm,
            ContractTypeForm,
            ContractCoversFullAcademicYearForm,
            TimetabledTeachingHoursForm,
            TaughtAtLeastOneAcademicTermForm,
            PerformanceAndDisciplineForm,
            TeachingHoursPerWeekForm,
            HalfTeachingHoursForm,
            HalfTimetabledTeachingTimeForm,
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

            fail "Current form #{current_slug} is not reachable" if index.nil?
            fail "Current form #{current_slug} is the first form" if index.zero?

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

          def message
            if completed? && eligibility.claimant_not_employed_by_college?
              return "Employment check for #{claim.full_name} submitted"
            end

            if completed?
              return "Claim Verified for #{claim.full_name}"
            end

            # We've just finished the employyment check section of the wizard
            if current_slug == "claimant_employment_check_declaration"
              "Employment check for #{claim.full_name} submitted"
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

            if eligibility.employment_check_required?
              @reachable_steps << ClaimantEmploymentCheckNeededForm
              @reachable_steps << ClaimantEmployedByCollegeForm
            end

            if eligibility.claimant_not_employed_by_college?
              return @reachable_steps
            end

            if eligibility.employment_check_required?
              @reachable_steps << ClaimantPersonalDetailsForm
              @reachable_steps << ClaimantEmploymentCheckDeclarationForm
            end

            @reachable_steps << ContinueVerificationForm
            @reachable_steps << TeachingResponsibilitiesForm
            @reachable_steps << InFirstFiveYearsForm
            @reachable_steps << TeachingQualificationForm
            @reachable_steps << ContractTypeForm

            if eligibility.provider_verification_contract_type == "fixed_term"
              @reachable_steps << ContractCoversFullAcademicYearForm
            end

            if eligibility.provider_verification_contract_type == "variable_hours"
              @reachable_steps << TimetabledTeachingHoursForm
              @reachable_steps << TaughtAtLeastOneAcademicTermForm
            end

            @reachable_steps << PerformanceAndDisciplineForm
            @reachable_steps << TeachingHoursPerWeekForm
            @reachable_steps << HalfTeachingHoursForm
            @reachable_steps << HalfTimetabledTeachingTimeForm
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
