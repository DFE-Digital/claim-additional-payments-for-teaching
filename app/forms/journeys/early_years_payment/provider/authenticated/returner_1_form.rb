module Journeys
  module EarlyYearsPayment
    module Provider
      module Authenticated
        class Returner1Form < Form
          attribute :first_job_within_6_months, :boolean

          validates :first_job_within_6_months,
            inclusion: {in: [true, false], message: i18n_error_message(:inclusion)}

          def save
            return false if invalid?

            journey_session.answers.assign_attributes(first_job_within_6_months:)
            journey_session.save!
          end
        end
      end
    end
  end
end
