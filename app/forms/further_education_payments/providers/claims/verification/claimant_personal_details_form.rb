module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ClaimantPersonalDetailsForm < BaseForm
          include ActiveRecord::AttributeAssignment

          class InvalidDate < Struct.new(:day, :month, :year, keyword_init: true)
            def future?
              false
            end
          end

          attribute :provider_verification_claimant_date_of_birth, :date
          attribute :provider_verification_claimant_postcode, :string
          attribute :provider_verification_claimant_national_insurance_number, :string, strip_all_whitespace: true
          attribute :provider_verification_claimant_bank_details_match, :boolean
          attribute :provider_verification_claimant_email, :string

          validate :date_of_birth_criteria

          validates(
            :provider_verification_claimant_national_insurance_number,
            presence: {
              message: "Enter their National Insurance number"
            }
          )

          validates(
            :provider_verification_claimant_national_insurance_number,
            national_insurance_number_format: {
              message: "Enter a valid National Insurance number"
            },
            if: -> { provider_verification_claimant_national_insurance_number.present? }
          )

          validates(
            :provider_verification_claimant_postcode,
            presence: {
              message: "Enter their postcode"
            }
          )

          validates(
            :provider_verification_claimant_postcode,
            length: {
              maximum: AddressForm::POSTCODE_MAX_CHARS,
              message: "Postcode must be 11 characters or less"
            },
            postcode_format: {
              message: "Enter a valid postcode"
            },
            if: -> { provider_verification_claimant_postcode.present? }
          )

          validates(
            :provider_verification_claimant_bank_details_match,
            inclusion: {
              in: ->(form) { form.claimant_bank_details_match_options.map(&:id) },
              message: ->(form, _) do
                "Select yes if these bank details match what you have for #{form.claimant_name}?"
              end
            }
          )

          validates(
            :provider_verification_claimant_email,
            presence: {
              message: "Enter their work email address"
            }
          )

          validates(
            :provider_verification_claimant_email,
            email_address_format: {
              message: "Enter a valid email address"
            },
            length: {
              maximum: Rails.application.config.email_max_length,
              message: "Email address must be #{Rails.application.config.email_max_length} characters or less"
            },
            if: -> { provider_verification_claimant_email.present? }
          )

          def assign_attributes(params)
            super

            self.provider_verification_claimant_date_of_birth = build_date(params)
          rescue ActiveRecord::MultiparameterAssignmentErrors
            self.provider_verification_claimant_date_of_birth = build_date(params)
          end

          def claimant_bank_details_match_options
            [
              Form::Option.new(id: true, name: "Yes"),
              Form::Option.new(id: false, name: "No")
            ]
          end

          def claimant_banking_name
            claim.banking_name
          end

          def claimant_bank_sort_code
            claim.bank_sort_code
          end

          def claimant_bank_account_number_obfuscated
            "****" + claim.bank_account_number.chars.last(4).join("")
          end

          private

          # Due to the valdiation errors we need to show on the form, we can't
          # use straight forward multiparameter assignment for the date of
          # birth.
          # When date params are set from the form they come in as multi part
          # date params. When they are set from the model they come in as a
          # single date param.
          def build_date(params)
            if params.keys.any? { |k| k.match?(/\(\di\)/) }
              year = params[:"provider_verification_claimant_date_of_birth(1i)"]
              month = params[:"provider_verification_claimant_date_of_birth(2i)"]
              day = params[:"provider_verification_claimant_date_of_birth(3i)"]
            else
              date = params[:provider_verification_claimant_date_of_birth].presence

              year = date&.year
              month = date&.month
              day = date&.day
            end

            if year.present? && month.present? && day.present?
              Date.new(year.to_i, month.to_i, day.to_i)
            else
              InvalidDate.new(year: year, month: month, day: day)
            end
          rescue Date::Error
            InvalidDate.new(year: year, month: month, day: day)
          end

          def date_of_birth_criteria
            if date_parts.all?(&:blank?)
              errors.add(
                :provider_verification_claimant_date_of_birth,
                "Enter their date of birth"
              )
            elsif date_parts.any?(&:blank?)
              errors.add(
                :provider_verification_claimant_date_of_birth,
                "Date of birth must include a day, month and year in the correct " \
                "format, for example 01 01 1980"
              )
            elsif provider_verification_claimant_date_of_birth.is_a?(InvalidDate)
              errors.add(
                :provider_verification_claimant_date_of_birth,
                "Enter a valid date of birth"
              )
            elsif provider_verification_claimant_date_of_birth.future?
              errors.add(
                :provider_verification_claimant_date_of_birth,
                "Date of birth must be in the past"
              )
            elsif provider_verification_claimant_date_of_birth.year < 1000
              errors.add(
                :provider_verification_claimant_date_of_birth,
                "Year must include 4 numbers"
              )
            elsif provider_verification_claimant_date_of_birth.year < 1900
              errors.add(
                :provider_verification_claimant_date_of_birth,
                "Year must be after 1900"
              )
            end
          end

          def date_parts
            [
              provider_verification_claimant_date_of_birth.day,
              provider_verification_claimant_date_of_birth.month,
              provider_verification_claimant_date_of_birth.year
            ]
          end
        end
      end
    end
  end
end
