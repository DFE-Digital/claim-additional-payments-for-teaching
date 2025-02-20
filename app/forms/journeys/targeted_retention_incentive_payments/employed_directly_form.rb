module Journeys
  module TargetedRetentionIncentivePayments
    class EmployedDirectlyForm < Form
      attribute :employed_directly, :boolean

      validates :employed_directly, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) },
        message: i18n_error_message(:inclusion)
      }

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          employed_directly: employed_directly
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
