module Journeys
  module TargetedRetentionIncentivePayments
    class TeachingSubjectNowForm < Form
      attribute :teaching_subject_now, :boolean

      validates :teaching_subject_now, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) },
        message: i18n_error_message(:inclusion)
      }

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          teaching_subject_now: teaching_subject_now
        )

        journey_session.save!
      end

      def radio_options
        [
          Option.new(id: true, name: t("options.true")),
          Option.new(id: false, name: t("options.false"))
        ]
      end
    end
  end
end
