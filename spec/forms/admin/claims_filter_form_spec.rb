require "rails_helper"

RSpec.describe Admin::ClaimsFilterForm, type: :model do
  describe "#claims" do
    context "when rejected whilst awaiting provider verification" do
      let!(:claim) do
        create(
          :claim,
          :rejected,
          :awaiting_provider_verification,
          policy: Policies::FurtherEducationPayments
        )
      end

      let(:session) { {} }
      let(:filters) { {status: "awaiting_provider_verification"} }

      subject { described_class.new(filters:, session:) }

      it "filtering by status awaiting provider verification excludes them" do
        expect(subject.claims).not_to include(claim)
      end
    end

    context "when the status is awaiting_provider_verification" do
      it "returns the expected claims" do
        claim_awaiting_provider_verification_1 = build(
          :claim,
          :submitted
        )

        create(
          :further_education_payments_eligibility,
          claim: claim_awaiting_provider_verification_1,
          flagged_as_duplicate: false
        )

        claim_awaiting_provider_verification_2 = build(
          :claim,
          :submitted
        )

        create(
          :further_education_payments_eligibility,
          claim: claim_awaiting_provider_verification_2,
          flagged_as_duplicate: true
        )

        create(
          :note,
          claim: claim_awaiting_provider_verification_2,
          label: "provider_verification"
        )

        create(
          :note,
          claim: claim_awaiting_provider_verification_2,
          label: "provider_verification"
        )

        _claim_not_awating_provider_verification = build(:claim, :submitted)

        create(
          :further_education_payments_eligibility,
          :verified
        )

        form = described_class.new(
          session: {},
          filters: {
            status: "awaiting_provider_verification"
          }
        )

        expect(form.claims).to match_array(
          [
            claim_awaiting_provider_verification_1,
            claim_awaiting_provider_verification_2
          ]
        )
      end
    end

    context "filtering for unassigned + auto approved claims" do
      subject { described_class.new(session:, filters: {team_member:, status:}) }

      let(:team_member) { "unassigned" }
      let(:status) { "automatically_approved" }
      let(:session) { {} }

      before do
        create(:claim, :submitted, :auto_approved, :current_academic_year)
      end

      it "works" do
        expect(subject.claims.count).to eql(1)
      end
    end
  end
end
