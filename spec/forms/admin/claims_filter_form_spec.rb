require "rails_helper"

RSpec.describe Admin::ClaimsFilterForm, type: :model do
  describe "#claims" do
    context "when rejected whilst awaiting provider verification" do
      let!(:claim) do
        create(
          :claim,
          :rejected,
          :awaiting_provider_verification,
          policy: Policies::FurtherEducationPayments,
        )
      end

      let(:session) { {} }
      let(:filters) { { status: "awaiting_provider_verification" } }

      subject { described_class.new(filters:, session:) }

      it "filtering by status awaiting provider verification excludes them" do
        expect(subject.claims).not_to include(claim)
      end
    end
  end
end
