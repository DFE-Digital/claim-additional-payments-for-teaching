module Journeys
  module AdditionalPaymentsForTeaching
    class EligibleDegreeSubjectForm < Form
      attribute :eligible_degree_subject, :boolean

      validates :eligible_degree_subject, inclusion: {in: [true, false], message: i18n_error_message(:inclusion)}

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          eligible_degree_subject: eligible_degree_subject
        )

        journey_session.save!
      end
    end
  end
end
