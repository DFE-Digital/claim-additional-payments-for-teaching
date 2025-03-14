module Journeys
  module FurtherEducationPayments
    module Provider
      class VerifyIdentityForm < Form
        class InvalidDate < Struct.new(:day, :month, :year, keyword_init: true); end

        attribute :"claimant_date_of_birth(3i)", :integer
        attribute :"claimant_date_of_birth(2i)", :integer
        attribute :"claimant_date_of_birth(1i)", :integer
        attribute :claimant_postcode, :string
        attribute :claimant_national_insurance_number, :string
        attribute :claimant_valid_passport, :boolean
        attribute :claimant_passport_number, :string
        attribute :declaration, :boolean
        attr_reader :day
        attr_reader :month
        attr_reader :year

        validate :date_of_birth_criteria

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

        def initialize(...)
          super

          set_date_of_birth_attributes
        end

        def claimant_date_of_birth
          if Date.valid_date?(year, month, day)
            Date.new(year, month, day)
          else
            InvalidDate.new(year: year, month: month, day: day)
          end
        end

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

        private

        def set_date_of_birth_attributes
          @day = send(:"claimant_date_of_birth(3i)") || answers.claimant_date_of_birth&.day
          @month = send(:"claimant_date_of_birth(2i)") || answers.claimant_date_of_birth&.month
          @year = send(:"claimant_date_of_birth(1i)") || answers.claimant_date_of_birth&.year
        end

        def date_of_birth_criteria
          if [day, month, year].all?(&:blank?)
            errors.add(
              :claimant_date_of_birth,
              t(
                "claimant_date_of_birth.errors.blank",
                claimant: claimant_first_name
              )
            )
          elsif [day, month, year].any?(&:blank?)
            errors.add(
              :claimant_date_of_birth,
              t("claimant_date_of_birth.errors.format")
            )
          elsif claimant_date_of_birth.is_a?(InvalidDate)
            errors.add(
              :claimant_date_of_birth,
              t("claimant_date_of_birth.errors.invalid")
            )
          elsif claimant_date_of_birth.future?
            errors.add(
              :claimant_date_of_birth,
              t("claimant_date_of_birth.errors.in_future")
            )
          elsif claimant_date_of_birth.year < 1000
            errors.add(
              :claimant_date_of_birth,
              t("claimant_date_of_birth.errors.four_digits")
            )
          elsif claimant_date_of_birth.year < 1900
            errors.add(
              :claimant_date_of_birth,
              t("claimant_date_of_birth.errors.before_1900")
            )
          end
        end
      end
    end
  end
end
