require "rails_helper"

RSpec.describe FurtherEducationPayments::ProvidersHelper do
  describe "#claim_status_tag" do
    let(:claim) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, eligibility: eligibility) }

    context "when provider verification is not started" do
      let(:eligibility) do
        create(:further_education_payments_eligibility,
          provider_verification_started_at: nil,
          provider_verification_completed_at: nil)
      end

      it "returns a red 'Not started' tag" do
        result = helper.claim_status_tag(claim)
        expect(result).to include("Not started")
        expect(result).to include("govuk-tag--red")
      end
    end

    context "when provider verification is in progress" do
      let(:eligibility) do
        create(:further_education_payments_eligibility,
          provider_verification_started_at: Time.current,
          provider_verification_completed_at: nil)
      end

      it "returns a yellow 'In progress' tag" do
        result = helper.claim_status_tag(claim)
        expect(result).to include("In progress")
        expect(result).to include("govuk-tag--yellow")
      end
    end

    context "when provider verification is completed" do
      let(:eligibility) do
        create(:further_education_payments_eligibility,
          provider_verification_started_at: 1.hour.ago,
          provider_verification_completed_at: Time.current)
      end

      it "returns a green 'Completed' tag" do
        result = helper.claim_status_tag(claim)
        expect(result).to include("Completed")
        expect(result).to include("govuk-tag--green")
      end
    end

    context "when status is unknown" do
      let(:eligibility) { create(:further_education_payments_eligibility) }

      before do
        allow(claim.eligibility).to receive(:provider_verification_status).and_return("unknown_status")
      end

      it "returns a grey 'Unknown' tag" do
        result = helper.claim_status_tag(claim)
        expect(result).to include("Unknown")
        expect(result).to include("govuk-tag--grey")
      end
    end
  end
end
