module Journeys
  module TargetedRetentionIncentivePayments
    class EntireTermContractForm < Form
      attribute :has_entire_term_contract, :boolean

      validates :has_entire_term_contract, inclusion: {
        in: ->(form) { form.radio_options.map(&:id) },
        message: i18n_error_message(:inclusion)
      }

      def save
        return false unless valid?

        journey_session.answers.assign_attributes(
          has_entire_term_contract: has_entire_term_contract
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
