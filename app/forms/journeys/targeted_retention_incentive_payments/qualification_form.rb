module Journeys
  module TargetedRetentionIncentivePayments
    class QualificationForm < Form
      QUALIFICATION_OPTIONS = %w[
        postgraduate_itt
        undergraduate_itt
        assessment_only
        overseas_recognition
      ].freeze

      attribute :qualification, :string

      validates :qualification, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) },
        message: i18n_error_message(:inclusion)
      }

      def save
        return false unless valid?
        return true unless qualification_changed?

        journey_session.answers.assign_attributes(qualification: qualification)

        # If some data was derived from DQT we do not want to reset these.
        unless answers.qualifications_details_check
          journey_session.answers.assign_attributes(
            eligible_itt_subject: nil,
            teaching_subject_now: nil
          )
        end

        journey_session.save!

        true
      end

      def save!
        raise ActiveRecord::RecordInvalid.new unless save
      end

      def radio_options
        QUALIFICATION_OPTIONS.map do |option|
          Option.new(
            id: option,
            name: t("options.#{option}"),
            hint: try_t("hints.#{option}")
          )
        end
      end

      private

      def qualification_changed?
        answers.qualification != qualification
      end
    end
  end
end

