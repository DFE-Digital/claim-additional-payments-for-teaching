module Journeys
  module TargetedRetentionIncentivePayments
    class EligibleDegreeSubjectForm < Form
      attribute :eligible_degree_subject, :boolean

      validates :eligible_degree_subject, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) },
        message: i18n_error_message(:inclusion)
      }

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          eligible_degree_subject: eligible_degree_subject
        )

        journey_session.save!

        true
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
