require "rails_helper"

RSpec.describe DfeIdentityCallbackForm do
  before do
    create(:journey_configuration, :additional_payments)
    create(:journey_configuration, :student_loans)
  end

  let(:ecp_claim) do
    create(
      :claim,
      policy: Policies::EarlyCareerPayments,
      details_check: true,
      logged_in_with_tid: nil
    )
  end

  let(:lup_claim) do
    create(
      :claim,
      policy: Policies::LevellingUpPremiumPayments,
      details_check: true,
      logged_in_with_tid: nil
    )
  end

  let(:current_claim) { CurrentClaim.new(claims: [ecp_claim, lup_claim]) }

  describe "#save!" do
    let(:form) do
      described_class.new(
        claim: current_claim,
        journey: Journeys::AdditionalPaymentsForTeaching,
        params: params
      )
    end

    before { form.save! }

    context "when there is no payload from DfE Sign-in" do
      let(:params) { {teacher_id_user_info: {}} }

      it "resets the details check flag" do
        expect(ecp_claim.details_check).to be nil
        expect(lup_claim.details_check).to be nil
      end

      it "sets the claim as signed in with teacher id" do
        expect(ecp_claim.logged_in_with_tid).to be true
        expect(lup_claim.logged_in_with_tid).to be true
      end

      it "doesn't set teacher_id_user_info" do
        expect(ecp_claim.teacher_id_user_info).to be_empty
        expect(lup_claim.teacher_id_user_info).to be_empty
      end
    end

    context "when there is a payload from DfE Sign-in" do
      let(:params) { {teacher_id_user_info: {trn: "1234567"}} }

      it "resets the details check flag" do
        expect(ecp_claim.details_check).to be nil
        expect(lup_claim.details_check).to be nil
      end

      it "sets the claim as signed in with teacher id" do
        expect(ecp_claim.logged_in_with_tid).to be true
        expect(lup_claim.logged_in_with_tid).to be true
      end

      it "doesn't set teacher_id_user_info" do
        expect(ecp_claim.teacher_id_user_info).to eq("trn" => "1234567")
        expect(lup_claim.teacher_id_user_info).to eq("trn" => "1234567")
      end
    end
  end
end
