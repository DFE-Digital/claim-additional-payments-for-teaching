module Journeys
  module GetATeacherRelocationPayment
    class SubjectForm < Form
      attribute :subject, :string

      validates :subject, inclusion: {
        in: :available_options,
        message: i18n_error_message(:inclusion)
      }

      def available_options
        if answers.trainee?
          %w[physics languages other]
        else
          %w[physics combined_with_physics languages other]
        end
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
