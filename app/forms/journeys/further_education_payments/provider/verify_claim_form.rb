module Journeys
  module FurtherEducationPayments
    module Provider
      class VerifyClaimForm < Form
        include CoursesHelper

        # When adding new assertions, try to use the same name as the attribute
        # in the eligibility model. This simplifies displaying the
        # corresponding claimant answer in the admin ui.
        ASSERTIONS = {
          fixed_contract: %i[
            contract_type
            teaching_responsibilities
            further_education_teaching_start_year
            teaching_hours_per_week
            half_teaching_hours
            subjects_taught
            subject_to_formal_performance_action
            subject_to_disciplinary_action
          ],
          variable_contract: %i[
            contract_type
            teaching_responsibilities
            further_education_teaching_start_year
            taught_at_least_one_term
            teaching_hours_per_week
            half_teaching_hours
            subjects_taught
            teaching_hours_per_week_next_term
            subject_to_formal_performance_action
            subject_to_disciplinary_action
          ]
        }

        attribute :assertions_attributes

        attribute :declaration, :boolean

        validates :declaration, acceptance: {
          message: i18n_error_message("declaration.acceptance")
        }

        validate :all_assertions_answered

        validate :claim_not_already_verified

        delegate :claim, to: :answers

        def claim_reference
          claim.reference
        end

        def claimant_name
          claim.full_name
        end

        def claimant_date_of_birth
          claim.date_of_birth.strftime("%-d %B %Y")
        end

        def claimant_trn
          claim.eligibility.teacher_reference_number
        end

        def claim_date
          claim.created_at.to_date.strftime("%-d %B %Y")
        end

        def course_descriptions
          @course_descriptions ||= claim.eligibility.courses_taught.map(&:description)
        end

        def claimant_contract_of_employment
          claimant_option_selected(
            "contract_type",
            claim.eligibility.contract_type
          ).downcase
        end

        def teaching_hours_per_week
          claimant_option_selected(
            "teaching_hours_per_week",
            claim.eligibility.teaching_hours_per_week
          ).downcase
        end

        def claimant_contract_duration
          if claim.eligibility.fixed_term_full_year
            "covering the full academic year "
          end
        end

        def assertions
          @assertions ||= ASSERTIONS.fetch(contract_type).map do |assertion_name|
            AssertionForm.new(name: assertion_name, parent_form: self)
          end
        end

        def assertions_attributes=(params)
          (params || {}).each do |_, assertion_params|
            assertions
              .detect { |a| a.name == assertion_params[:name] }
              &.assign_attributes(assertion_params)
          end
        end

        def save
          return false unless valid?

          ApplicationRecord.transaction do
            verified_at = DateTime.now

            claim.eligibility.update!(
              verification: {
                assertions: assertions.map(&:attributes),
                verifier: {
                  dfe_sign_in_uid: answers.dfe_sign_in_uid,
                  first_name: answers.dfe_sign_in_first_name,
                  last_name: answers.dfe_sign_in_last_name,
                  email: answers.dfe_sign_in_email,
                  dfe_sign_in_organisation_name: answers.dfe_sign_in_organisation_name,
                  dfe_sign_in_role_codes: answers.dfe_sign_in_role_codes
                },
                created_at: verified_at
              }
            )

            claim.verified_at = verified_at

            claim.save!
          end

          ClaimMailer
            .further_education_payment_provider_confirmation_email(claim)
            .deliver_later

          ClaimVerifierJob.perform_later(claim)

          true
        end

        def contract_type
          if claim.eligibility.long_term_employed?
            :fixed_contract
          else
            :variable_contract
          end
        end

        private

        def permitted_attributes
          super + [assertions_attributes: AssertionForm.attribute_names]
        end

        def claimant_option_selected(question, option)
          I18n.t(
            [
              "further_education_payments",
              "forms",
              question,
              "options",
              option
            ].join(".")
          )
        end

        # Make sure the errors in the summary link to the correct nested field
        def all_assertions_answered
          assertions.each(&:validate).each_with_index do |assertion, i|
            assertion.errors.each do |error|
              errors.add(
                "assertions_attributes[#{i}][#{error.attribute}]",
                error.message
              )
            end
          end
        end

        def claim_not_already_verified
          if claim.eligibility.verified?
            errors.add(:base, "Claim has already been verified")
          end
        end

        class AssertionForm
          include ActiveModel::Model
          include ActiveModel::Attributes

          attr_reader :parent_form

          attribute :name, :string
          attribute :outcome, :boolean

          validates :name, presence: true
          validates :outcome, inclusion: {
            in: [true, false],
            message: ->(form, _) do
              I18n.t(
                [
                  "further_education_payments_provider",
                  "forms",
                  "verify_claim",
                  "assertions",
                  form.contract_type,
                  form.name,
                  "errors",
                  "inclusion"
                ].join("."),
                claimant: form.claimant,
                provider: form.provider,
                hours: form.hours
              )
            end
          }

          def initialize(name:, parent_form:)
            @parent_form = parent_form

            super(name: name)
          end

          def radio_options
            [
              RadioOption.new(id: true, name: "Yes"),
              RadioOption.new(id: false, name: "No")
            ]
          end

          class RadioOption < Struct.new(:id, :name, keyword_init: true); end

          def claimant
            parent_form.claim.first_name
          end

          def provider
            parent_form.claim.school.name
          end

          def hours
            parent_form.teaching_hours_per_week
          end

          def contract_type
            parent_form.contract_type
          end
        end
      end
    end
  end
end
