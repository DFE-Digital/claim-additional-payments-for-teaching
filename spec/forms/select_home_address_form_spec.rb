require "rails_helper"

RSpec.describe SelectHomeAddressForm, type: :model do
  describe "#save" do
    subject(:save) { form.save }

    let(:address) { "The full address:123:Main Street:Springfield:12345" }
    let(:form) do
      described_class.new(
        journey: journey,
        journey_session: journey_session,
        params: params
      )
    end
    let(:journey) { Journeys::TeacherStudentLoanReimbursement }
    let(:journey_session) { build(:student_loans_session, answers:) }
    let(:answers) do
      attributes_for(
        :"#{journey.i18n_namespace}_answers",
        skip_postcode_search: false
      )
    end
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

    context "when an address is already selected and no new selection is submitted" do
      let(:answers) do
        attributes_for(
          :"#{journey.i18n_namespace}_answers",
          skip_postcode_search: false,
          address_line_1: "1 High Street",
          address_line_2: "Town Centre",
          address_line_3: "Springfield",
          postcode: "NE1 6EE"
        )
      end
      let(:params) { ActionController::Parameters.new(claim: {}) }

      it "is invalid and requires selecting an address" do
        expect(save).to be_falsey
        expect(form.errors[:address]).to include("Select an address")
      end
    end
  end
end
