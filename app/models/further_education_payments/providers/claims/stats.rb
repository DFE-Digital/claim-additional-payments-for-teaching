module FurtherEducationPayments
  module Providers
    module Claims
      class Stats
        attr_reader :school

        def initialize(school:)
          @school = school
        end

        def rejected_count
          rejected.count
        end

        def approved_count
          approved.count
        end

        def pending_decision_count
          pending_decision.count
        end

        def approved_amount
          approved_eligibilities = Policies::FurtherEducationPayments::Eligibility.where(
            claim: approved
          )

          approved_eligibilities.sum(:award_amount)
        end

        private

        # not used
        def amount_paid
          payments = Payment
            .confirmed
            .joins(:claims)
            .where(claims: claims)
            .sum(:award_amount)

          topups = Topup
            .joins(:claim, :payment)
            .where(claim: claims)
            .where("payments.confirmation_id IS NOT NULL")
            .sum(:award_amount)

          payments + topups
        end

        def claims
          @claims ||= Claim
            .where(eligibility_id: eligibilities.pluck(:id))
            .fe_provider_verified
            .by_academic_year(academic_year)
        end

        def eligibilities
          @eligibilities ||= Policies::FurtherEducationPayments::Eligibility
            .where(school:)
        end

        def pending_decision
          claims - approved - rejected
        end

        # approved + does not need QA
        # approved + needs QA and QA passed
        def approved
          claims.not_awaiting_qa
        end

        # rejected + does not need QA
        # rejected + needs QA and QA passed
        def rejected
          claims.rejected_not_awaiting_qa
        end

        def academic_year
          journey_configuration.current_academic_year
        end

        def journey_configuration
          @journey_configuration ||= Journeys::Configuration
            .find(Journeys::FurtherEducationPayments::ROUTING_NAME)
        end
      end
    end
  end
end
