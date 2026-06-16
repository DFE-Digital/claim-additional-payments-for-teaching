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

  describe "#identity_status" do
    subject(:identity_status) { described_class.new(claim).identity_status }

    let(:claim) do
      build(
        :claim,
        policy: Policies::EarlyYearsTeachersFinancialIncentivePayments,
        tasks: claim_tasks
      )
    end

    context "when there is no identity_confirmation task" do
      let(:claim_tasks) { [] }

      it { is_expected.to eq("Unverified") }
    end

    context "when the task passed" do
      let(:claim_tasks) do
        [
          build(
            :task,
            claim_verifier_match: nil,
            name: "one_login_identity",
            passed: true
          )
        ]
      end

      it { is_expected.to eq("Passed") }
    end

    context "when the task failed" do
      let(:claim_tasks) do
        [
          build(
            :task,
            claim_verifier_match: nil,
            name: "one_login_identity",
            passed: false
          )
        ]
      end

      it { is_expected.to eq("Failed") }
    end
  end
end
