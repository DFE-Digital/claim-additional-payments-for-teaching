module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class InFirstFiveYearsForm < BaseForm
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
            academic_years = Policies::FurtherEducationPayments.selectable_teaching_start_academic_years

            array = academic_years.map do |academic_year|
              Form::Option.new(
                id: academic_year.start_year.to_s,
                name: I18n.t(
                  "further_education_payments.forms.further_education_teaching_start_year.options.between_dates",
                  start_year: academic_year.start_year,
                  end_year: academic_year.end_year
                )
              )
            end

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
            Policies::FurtherEducationPayments.selectable_teaching_start_academic_years.last.start_year
          end
        end
      end
    end
  end
end
