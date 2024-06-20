module Journeys
  module GetATeacherRelocationPayment
    class TraineeDetailsForm < Form
      attribute :state_funded_secondary_school, :boolean

      validates :state_funded_secondary_school,
        inclusion: {
          in: [true, false],
          message: i18n_error_message(:inclusion)
        }

      def available_options
        [true, false]
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          state_funded_secondary_school: state_funded_secondary_school
        )

        journey_session.save!
      end
    end
  end
end
