module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class ClaimantPersonalDetailsForm < Form
          include DateOfBirth
          self.date_of_birth_field = :claimant_date_of_birth

          attribute :claimant_postcode, :string
          attribute :claimant_national_insurance_number
          attribute :claimant_bank_details_match, :boolean
          attribute :claimant_email, :string

          validates(
            :claimant_national_insurance_number,
            presence: {
              message: i18n_error_message("claimant_national_insurance_number.invalid")
            }
          )

          validates(
            :claimant_national_insurance_number,
            national_insurance_number_format: {
              message: i18n_error_message("claimant_national_insurance_number.invalid")
            },
            if: -> { claimant_national_insurance_number.present? }
          )

          validates(
            :claimant_postcode,
            presence: {
              message: i18n_error_message("claimant_postcode.blank")
            }
          )

          validates(
            :claimant_postcode,
            length: {
              maximum: AddressForm::POSTCODE_MAX_CHARS,
              message: i18n_error_message("claimant_postcode.length")
            },
            postcode_format: {
              message: i18n_error_message("claimant_postcode.format")
            },
            if: -> { claimant_postcode.present? }
          )

          validates(
            :claimant_bank_details_match,
            inclusion: {
              in: ->(form) { form.claimant_bank_details_match_options.map(&:id) },
              message: ->(form, _) do
                form.i18n_errors_path(
                  "claimant_bank_details_match.inclusion",
                  claimant_name: form.claimant_name
                )
              end
            }
          )

          validates(
            :claimant_email,
            presence: {
              message: i18n_error_message("claimant_email.blank")
            }
          )

          validates(
            :claimant_email,
            email_address_format: {
              message: "Enter an email address in the correct format, like name@example.com"
            },
            length: {
              maximum: Rails.application.config.email_max_length,
              message: ->(form, _) do
                form.i18n_errors_path(
                  "claimant_email.length",
                  max_length: Rails.application.config.email_max_length
                )
              end
            },
            if: -> { claimant_email.present? }
          )

          def claimant_name
            answers.claim.full_name
          end

          def claimant_bank_details_match_options
            [
              Option.new(id: true, name: "Yes"),
              Option.new(id: false, name: "No")
            ]
          end

          def claimant_banking_name
            answers.claim.banking_name
          end

          def claimant_bank_sort_code
            answers.claim.bank_sort_code
          end

          def claimant_bank_account_number
            answers.claim.bank_account_number
          end

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(
              claimant_date_of_birth: claimant_date_of_birth,
              claimant_postcode: claimant_postcode,
              claimant_national_insurance_number: claimant_national_insurance_number,
              claimant_bank_details_match: claimant_bank_details_match,
              claimant_email: claimant_email
            )
            journey_session.save!
          end

          def date_of_birth_blank_error_message
            i18n_errors_path(
              "claimant_date_of_birth.blank",
              claimant_name: claimant_name
            )
          end
        end
      end
    end
  end
end
