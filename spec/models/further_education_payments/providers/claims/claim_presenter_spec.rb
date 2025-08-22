require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::ClaimPresenter do
  describe "#status and #colour" do
    let(:claim) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, eligibility: eligibility) }
    let(:presenter) { described_class.new(claim) }

    context "when provider verification is not started" do
      let(:eligibility) do
        create(:further_education_payments_eligibility,
          provider_verification_started_at: nil,
          provider_verification_completed_at: nil)
      end

      it "returns 'Not started' status with yellow colour" do
        expect(presenter.status).to eq("Not started")
        expect(presenter.colour).to eq("yellow")
      end
    end

    context "when provider verification is in progress" do
      let(:eligibility) do
        create(:further_education_payments_eligibility,
          provider_verification_started_at: Time.current,
          provider_verification_completed_at: nil)
      end

      it "returns 'In progress' status with blue colour" do
        expect(presenter.status).to eq("In progress")
        expect(presenter.colour).to eq("blue")
      end
    end

    context "when provider verification is completed" do
      let(:eligibility) do
        create(:further_education_payments_eligibility,
          provider_verification_started_at: 1.hour.ago,
          provider_verification_completed_at: Time.current)
      end

      it "returns 'Completed' status with green colour" do
        expect(presenter.status).to eq("Completed")
        expect(presenter.colour).to eq("green")
      end
    end

    context "when status is unknown" do
      let(:eligibility) { create(:further_education_payments_eligibility) }

      before do
        allow(claim.eligibility).to receive(:provider_verification_status).and_return("unknown_status")
      end

      it "returns 'Unknown' status with grey colour" do
        expect(presenter.status).to eq("Unknown")
        expect(presenter.colour).to eq("grey")
      end
    end
  end

  describe "#processed_by" do
    let(:claim) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, eligibility: eligibility) }
    let(:eligibility) { create(:further_education_payments_eligibility) }
    let(:presenter) { described_class.new(claim) }

    it "delegates to eligibility.processed_by_label" do
      expect(eligibility).to receive(:processed_by_label).and_return("Test User")
      expect(presenter.processed_by).to eq("Test User")
    end
  end
end
