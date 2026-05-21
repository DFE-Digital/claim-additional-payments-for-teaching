require "rails_helper"

RSpec.describe Policies::EarlyYearsTeachersFinancialIncentivePayments::ClaimCheckingTasks do
  subject(:checking_tasks) { described_class.new(claim) }

  describe "#provider_claim_count" do
    context "when the claim limit is not exceeded" do
      it "doesn't include the provider claim count task" do
        eligible_eytfi_provider = create(
          :eligible_eytfi_provider,
          max_claims: 2
        )

        create(
          :claim,
          :submitted,
          :approved,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          eligibility_attributes: {
            eligible_eytfi_provider_urn: eligible_eytfi_provider.urn
          }
        )

        # Rejected claim, not counted
        create(
          :claim,
          :submitted,
          :rejected,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          eligibility_attributes: {
            eligible_eytfi_provider_urn: eligible_eytfi_provider.urn
          }
        )

        # claim at other provider, not counted
        create(
          :claim,
          :submitted,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          eligibility_attributes: {
            eligible_eytfi_provider_urn: create(:eligible_eytfi_provider)
          }
        )

        claim = create(
          :claim,
          :submitted,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          eligibility_attributes: {
            eligible_eytfi_provider_urn: eligible_eytfi_provider.urn
          }
        )

        expect(described_class.new(claim).applicable_task_names).not_to include(
          "provider_claim_count"
        )
      end
    end

    context "when the claim limit is exceeded" do
      it "includes the provider claim count task" do
        eligible_eytfi_provider = create(
          :eligible_eytfi_provider,
          max_claims: 2
        )

        2.times do
          create(
            :claim,
            :submitted,
            :approved,
            policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
            eligibility_attributes: {
              eligible_eytfi_provider_urn: eligible_eytfi_provider.urn
            }
          )
        end

        # Rejected claim, not counted
        create(
          :claim,
          :submitted,
          :rejected,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          eligibility_attributes: {
            eligible_eytfi_provider_urn: eligible_eytfi_provider.urn
          }
        )

        # claim at other provider, not counted
        create(
          :claim,
          :submitted,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          eligibility_attributes: {
            eligible_eytfi_provider_urn: create(:eligible_eytfi_provider)
          }
        )

        claim = create(
          :claim,
          :submitted,
          policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
          eligibility_attributes: {
            eligible_eytfi_provider_urn: eligible_eytfi_provider.urn
          }
        )

        expect(described_class.new(claim).applicable_task_names).to include(
          "provider_claim_count"
        )
      end
    end
  end
end
