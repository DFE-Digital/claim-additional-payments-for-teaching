module Journeys
  module GetATeacherRelocationPayment
    class SubjectForm < Form
      attribute :subject, :string

      validates :subject, inclusion: {
        in: :available_options,
        message: i18n_error_message(:inclusion)
      }

      def available_options
        %w[physics combined_with_physics languages other]
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(subject: subject)

        journey_session.save!

        true
      end
    end
  end
end
