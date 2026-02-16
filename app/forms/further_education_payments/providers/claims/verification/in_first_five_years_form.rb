module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class InFirstFiveYearsForm < BaseForm
          YEARS_BEFORE = -4

          attribute :provider_verification_teaching_start_year, :string

          validates(
            :provider_verification_teaching_start_year,
            included: {
              in: ->(form) { form.teaching_start_year_options.map(&:id) },
              message: ->(form, _) do
                "Select the academic year #{form.claimant_name} started " \
                "their FE teaching career in England"
              end
            },
            allow_nil: :save_and_exit?
          )

          def teaching_start_year_options
            array = (YEARS_BEFORE..0).map do |delta|
              academic_year = AcademicYear.current + delta
              Form::Option.new(
                id: academic_year.start_year.to_s,
                name: I18n.t(
                  "further_education_payments.forms.further_education_teaching_start_year.options.between_dates",
                  start_year: academic_year.start_year,
                  end_year: academic_year.end_year
                )
              )
            end.reverse

            array << Form::Option.new(
              id: "pre-#{before_year}",
              name: I18n.t(
                "further_education_payments.forms.further_education_teaching_start_year.options.before_date",
                year: before_year
              )
            )

            array
          end

          private

          def before_year
            academic_year = AcademicYear.current + YEARS_BEFORE
            academic_year.start_year
          end
        end
      end
    end
  end
end
