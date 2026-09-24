module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class NurserySearchForm < Form
      class NuseryJsonPresenter
        attr_reader :nursery

        def initialize(nursery)
          @nursery = nursery
        end

        def as_json
          {
            id: nursery.id,
            name: nursery.name,
            address: nursery.address,
            closeDate: nil
          }
        end
      end

      attribute :nursery_search_query, :string

      attribute :nursery_id, :string

      validates(
        :nursery_search_query,
        presence: {
          message: "Search term must have a minimum of 3 characters"
        }
      )

      validates(
        :nursery_search_query,
        length: {
          minimum: 3,
          message: "Search term must have a minimum of 3 characters"
        },
        if: -> { nursery_search_query.present? }
      )

      def save
        return false unless valid?

        journey_session.answers.update!(
          nursery_search_query: nursery_search_query,
          nursery_id: nursery_id.presence
        )

        recheck_employment!

        true
      end

      def completed?
        journey_session.answers.nursery_search_query.present?
      end

      def results
        @results ||= Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider
          .by_academic_year(Journeys::EarlyYearsTeachersFinancialIncentivePayments.configuration.current_academic_year)
          .search(nursery_search_query)
          .map(&NuseryJsonPresenter.method(:new))
          .map(&:as_json)
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
