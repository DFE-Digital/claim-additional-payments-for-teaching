module Journeys
  module TargetedRetentionIncentivePayments
    class QualificationDetailsForm < Form
      attribute :qualifications_details_check, :boolean

      validates :qualifications_details_check, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) },
        message: i18n_error_message(:inclusion)
      }

      def radio_options
        [
          Option.new(id: true, name: t("options.true")),
          Option.new(id: false, name: t("options.false"))
        ]
      end

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          qualifications_details_check: qualifications_details_check
        )

        if qualifications_details_check
          journey_session.answers.assign_attributes(
            qualification: dqt_or_answers(:qualification),
            itt_academic_year: dqt_or_answers(:itt_academic_year),
            eligible_degree_subject: dqt_or_answers(:eligible_degree_subject?),
            eligible_itt_subject: dqt_or_answers(:eligible_itt_subject)
          )
        else
          journey_session.answers.assign_attributes(
            qualification: nil,
            itt_academic_year: nil,
            eligible_degree_subject: nil,
            eligible_itt_subject: nil
          )
        end

        journey_session.save!
      end

      private

      def dqt_or_answers(name)
        answers.public_send("dqt_#{name}") || answers.public_send(name)
      end
    end
  end
end
