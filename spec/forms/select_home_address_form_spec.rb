require "rails_helper"

RSpec.describe SelectHomeAddressForm, type: :model do
  describe "#save" do
    subject(:save) { form.save }

    let(:address) { "The full address:123:Main Street:Springfield:12345" }
    let(:form) do
      described_class.new(
        claim: CurrentClaim.new(claims: [build(:claim)]),
        journey: journey,
        journey_session: journey_session,
        params: params
      )
    end
    let(:journey) { Journeys::TeacherStudentLoanReimbursement }
    let(:journey_session) { build(:student_loans_session) }
    let(:params) { ActionController::Parameters.new(claim: {address:}) }

    it { is_expected.to be_truthy }

    it "splits the address and assigns it to the current claim" do
      save
      answers = journey_session.reload.answers
      expect(answers.address_line_1).to eq("123")
      expect(answers.address_line_2).to eq("Main Street")
      expect(answers.address_line_3).to eq("Springfield")
      expect(answers.postcode).to eq("12345")
    end

    context "when the form is invalid" do
      let(:address) { nil }

      it { is_expected.to be_falsey }
    end
  end
end
