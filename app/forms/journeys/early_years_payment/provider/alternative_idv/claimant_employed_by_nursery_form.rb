module Journeys
  module EarlyYearsPayment
    module Provider
      module AlternativeIdv
        class ClaimantEmployedByNurseryForm < Form
          attribute :claimant_employed_by_nursery, :boolean

          validates(
            :claimant_employed_by_nursery,
            inclusion: {
              in: ->(form) { form.claimant_employed_by_nursery_options.map(&:id) },
              message: ->(form, _) do
                form.i18n_errors_path(
                  "claimant_employed_by_nursery.inclusion",
                  claimant_name: form.claimant_name,
                  nursery_name: form.nursery_name
                )
              end
            }
          )

          def claimant_employed_by_nursery_options
            [
              Option.new(id: true, name: "Yes"),
              Option.new(id: false, name: "No")
            ]
          end

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(
              claimant_employed_by_nursery: claimant_employed_by_nursery
            )

            journey_session.save!

            if !claimant_employed_by_nursery
              # We exit the journey early, so we need to mark the verification
              # as complete
              journey_session.answers.alternative_idv_completed!
            end

            true
          end

          def nursery_name
            answers.nursery.nursery_name
          end

          def claimant_name
            answers.claim.full_name
          end
        end
      end
    end
  end
end
