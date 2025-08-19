require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::CheckAnswersForm, type: :model do
  let(:user) { create(:dfe_signin_user) }

  let(:claim) do
    create(
      :claim,
      :further_education,
      eligibility_trait: :provider_verifiable
    )
  end

  let(:params) { {} }

  subject(:form) do
    described_class.new(
      claim: claim,
      user: user,
      params: params
    )
  end

  describe "validations" do
    it do
      is_expected.to(
        validate_presence_of(:provider_verification_declaration)
        .with_message(
          "Tick the box to confirm that the information provided in this " \
          "form is correct to the best of your knowledge"
        )
      )
    end
  end

  describe "#save" do
    let(:params) do
      {
        provider_verification_declaration: true
      }
    end

    context "with an incomplete form" do
      before do
        claim.eligibility.update!(
          provider_verification_teaching_responsibilities: nil
        )
      end

      it "throws an error" do
        expect { form.save }.to raise_error(
          described_class::IncompleteWizardError
        )
      end
    end

    context "with a complete form" do
      let(:verified_at) { DateTime.new(2025, 1, 1, 0, 0, 0) }

      before do
        travel_to(verified_at) do
          form.save
        end
      end

      it "sets the claim as verified" do
        expect(
          claim.eligibility.provider_verification_completed_at
        ).to eq(verified_at)
      end

      it "records who verified the claim" do
        expect(
          claim.eligibility.provider_verification_verified_by_id
        ).to eq(user.id)
      end
    end

    context "when alternative IDV was completed" do
      it "calls the alternative IDV completed hook" do
        claim.eligibility.update!(
          provider_verification_claimant_employment_check_declaration: true
        )

        allow(Policies::FurtherEducationPayments).to(
          receive(:alternative_idv_completed!)
        )

        form.save

        expect(Policies::FurtherEducationPayments).to(
          have_received(:alternative_idv_completed!).with(claim)
        )
      end
    end

    context "when alternative IDV was not completed" do
      it "calls the alternative IDV completed hook" do
        claim.eligibility.update!(
          provider_verification_claimant_employment_check_declaration: false
        )

        allow(Policies::FurtherEducationPayments).to(
          receive(:alternative_idv_completed!)
        )

        form.save

        expect(Policies::FurtherEducationPayments).not_to(
          have_received(:alternative_idv_completed!).with(claim)
        )
      end
    end
  end
end
