module FurtherEducationPayments
  module Providers
    module Claims
      module Verification
        class ContractCoversFullAcademicYearForm < BaseForm
          attribute(
            :provider_verification_contract_covers_full_academic_year,
            :boolean
          )

          attribute(
            :provider_verification_contract_covers_section_completed,
            :boolean
          )

          validates(
            :provider_verification_contract_covers_full_academic_year,
            inclusion: {
              in: ->(form) { form.contract_covers_full_academic_year_options.map(&:id) }
            }
          )

          def claimant_name
            claim.full_name
          end

          def academic_year
            claim.academic_year
          end

          def academic_year_start_to_end
            [
              "September #{academic_year.start_year}",
              "July #{academic_year.end_year}"
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
        end
      end
    end
  end
end
