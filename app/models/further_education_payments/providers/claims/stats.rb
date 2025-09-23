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

        private

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

        def approved
          claims.approved
        end

        def rejected
          claims.rejected
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
