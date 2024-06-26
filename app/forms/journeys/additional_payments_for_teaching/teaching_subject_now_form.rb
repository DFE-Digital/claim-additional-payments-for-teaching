module Journeys
  module AdditionalPaymentsForTeaching
    class TeachingSubjectNowForm < Form
      attribute :teaching_subject_now, :boolean

      validates :teaching_subject_now, inclusion: {in: [true, false], message: i18n_error_message(:inclusion)}

      def eligible_itt_subject
        @eligible_itt_subject ||= journey_session.answers.eligible_itt_subject
      end

      def teaching_physics_or_chemistry?
        eligible_itt_subject == "physics" || eligible_itt_subject == "chemistry"
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          teaching_subject_now: teaching_subject_now
        )

        journey_session.save!
      end
    end
  end
end
