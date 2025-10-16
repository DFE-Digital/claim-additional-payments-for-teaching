require "rails_helper"

RSpec.describe FurtherEducationPaymentsMailer, type: :mailer do
  describe "#provider_weekly_update" do
    let(:provider) do
      create(:dfe_signin_user,
        given_name: "Jane",
        family_name: "Doe",
        email: "jane.doe@example.com",
        organisation_name: "Springfield FE College")
    end

    let(:claim1) do
      create(:claim, :submitted,
        policy: Policies::FurtherEducationPayments,
        reference: "ABC123",
        eligibility: create(:further_education_payments_eligibility,
          :eligible,
          provider_assigned_to: provider))
    end

    let(:claim2) do
      create(:claim, :submitted,
        policy: Policies::FurtherEducationPayments,
        reference: "DEF456",
        eligibility: create(:further_education_payments_eligibility,
          :eligible,
          provider_assigned_to: provider))
    end

    let(:claim3) do
      create(:claim, :submitted,
        policy: Policies::FurtherEducationPayments,
        reference: "GHI789",
        created_at: 3.weeks.ago,
        eligibility: create(:further_education_payments_eligibility,
          :eligible,
          provider_assigned_to: provider))
    end

    let(:claims) { [claim1, claim2, claim3] }

    it "forms correct email with aggregated claim counts" do
      mail = described_class.with(provider: provider, claims: claims).provider_weekly_update

      expect(mail.to).to eql([provider.email])

      personalisation = mail.personalisation
      expect(personalisation["provider_name"]).to eql("Springfield FE College")
      expect(personalisation["number_not_started"]).to eql("2")
      expect(personalisation["number_in_progress"]).to eql("0")
      expect(personalisation["number_overdue"]).to eql("1")
      expect(personalisation["number_overall"]).to eql("3")

      expected_url = "https://#{ENV["CANONICAL_HOSTNAME"]}/further-education-payments/providers/claims"
      expect(personalisation["link_to_provider_dashboard"]).to eql(expected_url)
    end
  end

  describe "#provider_overdue_chaser" do
    let(:provider) do
      create(:dfe_signin_user,
        given_name: "John",
        family_name: "Smith",
        email: "john.smith@example.com",
        organisation_name: "Shelbyville FE College")
    end

    let(:claim) do
      create(:claim, :submitted,
        policy: Policies::FurtherEducationPayments,
        reference: "XYZ999",
        first_name: "Alice",
        surname: "Johnson",
        created_at: 3.weeks.ago,
        eligibility: create(:further_education_payments_eligibility,
          :eligible,
          provider_assigned_to: provider))
    end

    it "forms correct email with claim details and expiry date" do
      mail = described_class.with(claim: claim).provider_overdue_chaser

      expect(mail.to).to eql([provider.email])

      personalisation = mail.personalisation
      expect(personalisation["provider_name"]).to eql("Shelbyville FE College")
      expect(personalisation["claimant_name"]).to eql("Alice Johnson")
      expect(personalisation["claim_reference"]).to eql("XYZ999")

      # Expiry date should be due_date + 3 weeks = created_at + 2 weeks + 3 weeks
      expected_expiry = (claim.created_at + 5.weeks).to_date
      expect(personalisation["expiry_date"]).to eql(expected_expiry.to_fs(:long_date))

      expected_url = "https://#{ENV["CANONICAL_HOSTNAME"]}/further-education-payments/providers/claims"
      expect(personalisation["link_to_provider_dashboard"]).to eql(expected_url)
    end
  end
end
