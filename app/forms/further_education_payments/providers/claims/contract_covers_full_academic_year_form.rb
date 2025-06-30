module FurtherEducationPayments
  module Providers
    module Claims
      class ContractCoversFullAcademicYearForm
        include ActiveModel::Model
        include ActiveModel::Attributes

        attr_reader :claim, :user

        delegate :eligibility, to: :claim

        attribute(
          :provider_verification_contract_covers_full_academic_year,
          :boolean
        )

        attribute :section_completed, :boolean

        validates(
          :provider_verification_contract_covers_full_academic_year,
          inclusion: {
            in: ->(form) { form.contract_covers_full_academic_year_options.map(&:id) }
          }
        )

        def initialize(claim:, user:, params: {})
          @claim = claim
          @user = user

          super(params)
        end

        def incomplete?
          required? && dup.invalid?
        end

        def template
          "contract_covers_full_academic_year"
        end

        def update(params)
          assign_attributes(params)
          save
        end

        def save
          return false unless valid?

          # TODO RL: - handle recording who made the change
          claim.eligibility.update!(
            provider_verification_contract_covers_full_academic_year:,
          )

          true
        end

        def provider
          claim.eligibility.school
        end

        def claimant_name
          claim.full_name
        end

        def academic_year
          claim.academic_year
        end

        def academic_year_start_to_end
          [
            "September #{academic_year.start_year}",
            "July #{academic_year.end_year}",
          ].join(" to ")
        end

        def contract_covers_full_academic_year_options
          [
            Form::Option.new(id: true, name: "Yes"),
            Form::Option.new(id: false, name: "No")
          ]
        end

        def section_completed_options
          [
            Form::Option.new(
              id: true,
              name: "Yes"
            ),
            Form::Option.new(
              id: false,
              name: "No, I want to come back to it later"
            )
          ]
        end

        private

        def required?
          eligibility.provider_verification_contract_type.in? %w(
            fixed_term
            variable_hours
          )
        end
      end
    end
  end
end

