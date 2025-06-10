module Journeys
  module TeacherStudentLoanReimbursement
    class MostlyPerformedLeadershipDutiesForm < Form
      attribute :mostly_performed_leadership_duties, :boolean

      validates :mostly_performed_leadership_duties,
        inclusion: {
          in: [true, false],
          message: ->(form, _) { form.i18n_errors_path("inclusion") }
        }

      def save
        return false unless valid?
        journey_session.answers.assign_attributes(
          mostly_performed_leadership_duties: mostly_performed_leadership_duties
        )

        journey_session.save!
      end

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
    end
  end
end
