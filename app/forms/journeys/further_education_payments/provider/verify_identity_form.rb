module Journeys
  module FurtherEducationPayments
    module Provider
      class VerifyIdentityForm < Form
        attribute :"claimant_date_of_birth(3i)", :integer
        attribute :"claimant_date_of_birth(2i)", :integer
        attribute :"claimant_date_of_birth(1i)", :integer
        attribute :claimant_date_of_birth, :date
        attribute :claimant_postcode, :string
        attribute :claimant_national_insurance_number, :string
        attribute :claimant_valid_passport, :boolean
        attribute :claimant_passport_number, :string
        attribute :declaration, :boolean

        def initialize(...)
          super

          # Handle multi-parameter date attributes
          self.claimant_date_of_birth ||= [
            send(:"claimant_date_of_birth(1i)"),
            send(:"claimant_date_of_birth(2i)"),
            send(:"claimant_date_of_birth(3i)")
          ].join("-")
        end

        validates(
          :claimant_date_of_birth,
          presence: {
            message: ->(form, _) do
              form.t(
                "claimant_date_of_birth.errors.blank",
                claimant: form.claimant_first_name
              )
            end
          }
        )

        validates(
          :claimant_postcode,
          presence: {
            message: ->(form, _) do
              form.t(
                "claimant_postcode.errors.blank",
                claimant: form.claimant_first_name
              )
            end
          }
        )

        validates(
          :claimant_postcode,
          postcode_format: {
            message: ->(form, _) { form.t("claimant_postcode.errors.invalid") },
            if: -> { claimant_postcode.present? }
          }
        )

        validates(
          :claimant_national_insurance_number,
          presence: {
            message: ->(form, _) do
              form.t(
                "claimant_national_insurance_number.errors.blank",
                claimant: form.claimant_first_name
              )
            end
          }
        )

        validates(
          :claimant_national_insurance_number,
          national_insurance_number_format: {
            message: ->(form, _) do
              form.t("claimant_national_insurance_number.errors.invalid")
            end
          },
          if: -> { claimant_national_insurance_number.present? }
        )

        validates(
          :claimant_valid_passport,
          inclusion: {
            in: ->(form) { form.radio_options.map(&:id) },
            message: ->(form, _) do
              form.t(
                "claimant_valid_passport.errors.inclusion",
                claimant: form.claimant_first_name
              )
            end
          }
        )

        validates(
          :claimant_passport_number,
          presence: {
            message: ->(form, _) do
              form.t(
                "claimant_passport_number.errors.blank",
                claimant: form.claimant_first_name
              )
            end,
            if: :claimant_valid_passport
          }
        )

        validates(
          :declaration,
          acceptance: {
            message: ->(form, _) do
              form.t("declaration.errors.acceptance")
            end
          }
        )

        delegate :claim, to: :answers

        def claimant_first_name
          claim.first_name
        end

        def radio_options
          @radio_options ||= [
            Option.new(
              id: true,
              name: t("claimant_valid_passport.options.true")
            ),
            Option.new(
              id: false,
              name: t("claimant_valid_passport.options.false")
            )
          ]
        end

        def save
          return false unless valid?

          journey_session.answers.assign_attributes(
            claimant_date_of_birth: claimant_date_of_birth,
            claimant_postcode: claimant_postcode,
            claimant_national_insurance_number: claimant_national_insurance_number,
            claimant_valid_passport: claimant_valid_passport,
            claimant_passport_number: claimant_passport_number,
            claimant_identity_verified_at: DateTime.now
          )

          journey_session.save!

          ClaimSubmissionForm.new(journey_session: journey_session).save!

          true
        end
      end
    end
  end
end
