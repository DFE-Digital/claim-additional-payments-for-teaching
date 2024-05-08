require "rails_helper"

RSpec.describe ClaimSubmissionService do
  before do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :additional_payments)
  end

  let(:tslr_claim) do
    create(
      :claim,
      :submittable,
      policy: Policies::StudentLoans
    )
  end

  let(:ecp_eligibility) do
    build(
      :early_career_payments_eligibility,
      :eligible
    )
  end

  let(:ecp_claim) do
    create(
      :claim,
      :submittable,
      policy: Policies::EarlyCareerPayments,
      eligibility: ecp_eligibility
    )
  end

  let(:lup_eligibility) do
    build(
      :levelling_up_premium_payments_eligibility,
      :eligible,
      current_school: create(
        :school,
        :levelling_up_premium_payments_eligible,
        levelling_up_premium_payments_award_amount: 1_000
      )
    )
  end

  let(:lup_claim) do
    create(
      :claim,
      :submittable,
      policy: Policies::LevellingUpPremiumPayments,
      eligibility: lup_eligibility
    )
  end

  describe ".call" do
    around do |example|
      travel_to(DateTime.new(2024, 3, 1, 9, 0, 0)) { example.run }
    end

    before do
      allow(Policies::EarlyCareerPayments::AwardAmountCalculator).to(
        receive(:new).and_return(double(amount_in_pounds: BigDecimal("2000.0")))
      )

      allow(ClaimMailer).to receive(:submitted).and_return(
        double(deliver_later: true)
      )

      allow(ClaimVerifierJob).to receive(:perform_later)

      described_class.call(
        main_claim: main_claim,
        other_claims: other_claims
      )

      main_claim.reload
    end

    context "with an ecp claim" do
      let(:main_claim) { ecp_claim }
      let(:other_claims) { [lup_claim] }

      it "sets the main claim's submitted_at" do
        expect(main_claim.submitted_at).to eq(DateTime.new(2024, 3, 1, 9, 0, 0))
      end

      it "sets the main claim's reference" do
        expect(main_claim.reference).to match(/([A-HJ-NP-Z]|\d){8}/)
      end

      it "sets the eligibilities award amount" do
        expect(main_claim.eligibility.award_amount).to eq(2000.0)
      end

      it "sets the policy options provided" do
        expect(main_claim.policy_options_provided).to eq(
          [
            {
              "award_amount" => "2000.0",
              "policy" => "EarlyCareerPayments"
            },
            {
              "award_amount" => "1000.0",
              "policy" => "LevellingUpPremiumPayments"
            }
          ]
        )
      end

      it "remove other claims" do
        expect(Claim.where(id: other_claims.map(&:id))).to be_empty
      end

      it "sends claim submitted email" do
        expect(ClaimMailer).to have_received(:submitted).with(main_claim)
      end

      it "enqueues claim verifier job" do
        expect(ClaimVerifierJob).to(
          have_received(:perform_later).with(main_claim)
        )
      end
    end

    context "with an lup claim" do
      let(:main_claim) { lup_claim }
      let(:other_claims) { [ecp_claim] }

      it "sets the main claim's submitted_at" do
        expect(main_claim.submitted_at).to eq(DateTime.new(2024, 3, 1, 9, 0, 0))
      end

      it "sets the main claim's reference" do
        expect(main_claim.reference).to match(/([A-HJ-NP-Z]|\d){8}/)
      end

      it "sets the eligibilities award amount" do
        expect(main_claim.eligibility.award_amount).to eq(1000.0)
      end

      it "sets the policy options provided" do
        expect(main_claim.policy_options_provided).to eq(
          [
            {
              "award_amount" => "2000.0",
              "policy" => "EarlyCareerPayments"
            },
            {
              "award_amount" => "1000.0",
              "policy" => "LevellingUpPremiumPayments"
            }
          ]
        )
      end

      it "remove other claims" do
        expect(Claim.where(id: other_claims.map(&:id))).to be_empty
      end

      it "sends claim submitted email" do
        expect(ClaimMailer).to have_received(:submitted).with(main_claim)
      end

      it "enqueues claim verifier job" do
        expect(ClaimVerifierJob).to(
          have_received(:perform_later).with(main_claim)
        )
      end
    end

    context "with an tslr claim" do
      let(:main_claim) { tslr_claim }
      let(:other_claims) { [] }

      it "sets the main claim's submitted_at" do
        expect(main_claim.submitted_at).to eq(DateTime.new(2024, 3, 1, 9, 0, 0))
      end

      it "sets the main claim's reference" do
        expect(main_claim.reference).to match(/([A-HJ-NP-Z]|\d){8}/)
      end

      it "doesn't set the policy options provided" do
        expect(main_claim.policy_options_provided).to eq([])
      end

      it "remove other claims" do
        expect(Claim.where(id: other_claims.map(&:id))).to be_empty
      end

      it "sends claim submitted email" do
        expect(ClaimMailer).to have_received(:submitted).with(main_claim)
      end

      it "enqueues claim verifier job" do
        expect(ClaimVerifierJob).to(
          have_received(:perform_later).with(main_claim)
        )
      end
    end
  end
end
