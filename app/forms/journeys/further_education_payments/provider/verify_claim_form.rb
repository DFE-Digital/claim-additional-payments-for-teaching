module Journeys
  module FurtherEducationPayments
    module Provider
      class VerifyClaimForm < Form
        include CoursesHelper

        ASSERTIONS = {
          fixed_contract: %i[
            contract_type
            teaching_responsibilities
            further_education_teaching_start_year
            teaching_hours_per_week
            hours_teaching_eligible_subjects
            subjects_taught
          ],
          variable_contract: %i[
            contract_type
            teaching_responsibilities
            further_education_teaching_start_year
            taught_at_least_one_term
            teaching_hours_per_week
            hours_teaching_eligible_subjects
            subjects_taught
            teaching_hours_per_week_next_term
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

        def assertions
          @assertions ||= ASSERTIONS.fetch(contract_type).map do |assertion_name|
            AssertionForm.new(
              name: assertion_name,
              claim: claim,
              type: contract_type
            )
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

          claim.eligibility.update!(
            verification: {
              assertions: assertions.map(&:attributes),
              verifier: {
                dfe_sign_in_uid: answers.dfe_sign_in_uid,
                first_name: answers.dfe_sign_in_first_name,
                last_name: answers.dfe_sign_in_last_name,
                email: answers.dfe_sign_in_email
              },
              created_at: DateTime.now
            }
          )

          claim.save!

          true
        end

        def contract_type
          if claim.eligibility.fixed_contract?
            :fixed_contract
          else
            :variable_contract
          end
        end

        private

        def permitted_attributes
          super + [assertions_attributes: AssertionForm.attribute_names]
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

          attr_reader :claim, :type

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
                  form.type,
                  form.name,
                  "errors",
                  "inclusion"
                ].join("."),
                claimant: form.claimant,
                provider: form.provider
              )
            end
          }

          def initialize(name:, claim:, type:)
            @claim = claim
            @type = type

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
            claim.first_name
          end

          def provider
            claim.school.name
          end
        end
      end
    end
  end
end
