module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class NurserySelectForm < Form
      attribute :nursery_id, :string

      validates(
        :nursery_id,
        presence: {message: i18n_error_message(:blank)}
      )

      def radio_options
        results
      end

      def save
        return false unless valid?

        journey_session.answers.update!(nursery_id: nursery_id)

        true
      end

      def completed?
        journey_session.answers.nursery_id.present?
      end

      private

      def results
        @results ||= Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider
          .search(answers.nursery_search_query)
      end
    end
  end
end
