require "rails_helper"

RSpec.describe Admin::Amendments::EarlyYearsPaymentsForm do
  describe "#save" do
    context "when only the provider has completed their part of the claim" do
      it "allows amending the pracitioner email address" do
        claim = create(
          :claim,
          policy: Policies::EarlyYearsPayments,
          practitioner_email_address: "original-email-address@example.com"
        )

        form = described_class.new(
          claim: claim,
          admin_user: create(:dfe_signin_user)
        )

        expect(form).not_to be_valid

        form.practitioner_email_address = "new-email-address@example.com"

        expect(form).not_to be_valid

        form.notes = "some notes"

        expect(form).to be_valid
      end
    end
  end
end
