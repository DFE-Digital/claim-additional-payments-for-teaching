module FurtherEducationPayments
  module Providers
    module Claims
      class Stats
        attr_reader :provider, :journey_configuration

        def initialize(provider:)
          @provider = provider
          @journey_configuration = Journeys::FurtherEducationPayments.configuration
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

        def unverified_overdue_count
          unverified_not_rejected.verification_overdue.count
        end

        def unverified_in_progress_count
          unverified_not_rejected.verification_in_progress.count
        end

        def unverified_not_started_count
          unverified_not_rejected.verification_not_started.count
        end

        def unverified_overall_count
          unverified_not_rejected.count
        end

        # this is a fudged number
        # consists of approved amount
        # plus topups
        def amount
          approved_amount + topups
        end

        private

        def approved_amount
          approved_eligibilities = Policies::FurtherEducationPayments::Eligibility.where(
            claim: approved
          )

          approved_eligibilities.sum(:award_amount)
        end

        def topups
          Topup
            .joins(:claim)
            .where(claim: verified_claims)
            .sum(:award_amount)
        end

        def verified_claims
          @verified_claims ||= provider
            .claims.by_academic_year(academic_year)
            .verified
        end

        def unverified_not_rejected
          @unverified_not_rejected ||= provider
            .claims.by_academic_year(academic_year)
            .unverified
            .not_rejected
        end

        def pending_decision
          verified_claims - approved - rejected
        end

        # approved + does not need QA
        # approved + needs QA and QA passed
        def approved
          verified_claims.not_awaiting_qa
        end

        # rejected + does not need QA
        # rejected + needs QA and QA passed
        def rejected
          verified_claims.rejected_not_awaiting_qa
        end

        def academic_year
          journey_configuration.current_academic_year
        end
      end
    end
  end
end
