require "rails_helper"

RSpec.describe SelectHomeAddressForm, type: :model do
  describe "#save" do
    subject(:save) { form.save }

    let(:address) { "The full address:123:Main Street:Springfield:12345" }
    let(:claim) { CurrentClaim.new(claims: [build(:claim, policy: Policies::StudentLoans)]) }
    let(:form) { described_class.new(claim:, journey:, journey_session:, params:) }
    let(:journey) { Journeys::TeacherStudentLoanReimbursement }
    let(:journey_session) { build(:journeys_session, journey: journey::ROUTING_NAME) }
    let(:params) { ActionController::Parameters.new(claim: {address:}) }

    it { is_expected.to be_truthy }

    it "splits the address and assigns it to the current claim" do
      save
      expect(form.claim.address_line_1).to eq("123")
      expect(form.claim.address_line_2).to eq("Main Street")
      expect(form.claim.address_line_3).to eq("Springfield")
      expect(form.claim.postcode).to eq("12345")
    end

    context "when the form is invalid" do
      let(:address) { nil }

      it { is_expected.to be_falsey }
    end
  end
end
