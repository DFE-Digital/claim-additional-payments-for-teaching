module Journeys
  module AdditionalPaymentsForTeaching
    class PoorPerformanceForm < Form
      attribute :subject_to_formal_performance_action, :boolean
      attribute :subject_to_disciplinary_action, :boolean

      validates :subject_to_formal_performance_action, inclusion: {in: [true, false], message: i18n_error_message("subject_to_formal_performance_action.inclusion")}
      validates :subject_to_disciplinary_action, inclusion: {in: [true, false], message: i18n_error_message("subject_to_disciplinary_action.inclusion")}

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          subject_to_formal_performance_action:,
          subject_to_disciplinary_action:
        )

        journey_session.save
      end
    end
  end
end
