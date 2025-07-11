require "rails_helper"

RSpec.describe FurtherEducationPayments::ProvidersHelper do
  describe "#claim_status_tag" do
    let(:claim) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, eligibility: eligibility) }

    context "when provider verification is not started" do
      let(:eligibility) { create(:further_education_payments_eligibility) }

      it "returns a red 'Not started' tag" do
        result = helper.claim_status_tag(claim)
        expect(result).to include("Not started")
        expect(result).to include("govuk-tag--red")
      end
    end

    context "when provider verification is in progress" do
      let(:eligibility) do
        create(:further_education_payments_eligibility,
          provider_verification_teaching_responsibilities: true)
      end

      it "returns a yellow 'In progress' tag" do
        result = helper.claim_status_tag(claim)
        expect(result).to include("In progress")
        expect(result).to include("govuk-tag--yellow")
      end
    end
  end
end
