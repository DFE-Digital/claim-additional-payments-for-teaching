module FurtherEducationPayments
  module Providers
    module Claims
      class CheckAnswersForm
        include ActiveModel::Model
        include ActiveModel::Attributes

        attr_reader :claim, :user

        attribute :provider_verification_declaration, :boolean, default: false

        validates :provider_verification_declaration, acceptance: true

        delegate :eligibility, to: :claim

        delegate(
          :provider_verification_teaching_responsibilities,
          :provider_verification_in_first_five_years,
          :provider_verification_teaching_qualification,
          :provider_verification_contract_covers_full_academic_year,
          to: :eligibility
        )

        def initialize(claim:, user:, params: {})
          @claim = claim
          @user = user

          super(params)
        end

        def incomplete?
          dup.invalid?
        end

        def provider
          claim.eligibility.school
        end

        def template
          "check_answers"
        end

        def provider_verification_contract_type
          eligibility.provider_verification_contract_type.gsub("_", "-").capitalize
        end

        # FIXME RL: share this with contract_covers_full_academic_year_form
        # prob move to eligibility model
        def show_contract_type?
          eligibility.provider_verification_contract_type.in? %w(
            fixed_term
            variable_hours
          )
        end
      end
    end
  end
end
