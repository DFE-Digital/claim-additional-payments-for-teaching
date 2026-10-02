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

        recheck_employment!

        true
      end

      def completed?
        journey_session.answers.nursery_id.present?
      end

      private

      def results
        @results ||= Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider
          .by_academic_year(Journeys::EarlyYearsTeachersFinancialIncentivePayments.configuration.current_academic_year)
          .search(answers.nursery_search_query)
      end

      # We've changed nursery but not claimant details so we can reuse the
      # employment information we have from hmrc.
      def recheck_employment!
        if journey_session.answers.nursery.nil?
          journey_session.answers.update!(hmrc_employment_check_passed: nil)
        else
          employment_check = EmploymentCheck.new(
            setting: journey_session.answers.nursery,
            employments: Array.wrap(journey_session.answers.hmrc_employment_history)
          )

          journey_session.answers.update!(
            hmrc_employment_check_passed: employment_check.passed?
          )
        end
      end
    end
  end
end
