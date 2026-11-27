module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class TeacherQualificationsForm < Form
      attribute :correct_qualifications, :boolean

      validates :correct_qualifications,
        inclusion: {
          in: [true, false],
          message: "Select yes if your qualifications are correct"
        }

      def radio_options
        [
          Option.new(
            id: true,
            name: "Yes"
          ),
          Option.new(
            id: false,
            name: "No"
          )
        ]
      end

      def save
        return false if invalid?

        journey_session.answers.update!(
          correct_qualifications:
        )
      end
    end
  end
end
