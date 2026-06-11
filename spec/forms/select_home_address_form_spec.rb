require "rails_helper"

RSpec.describe SelectHomeAddressForm, type: :model do
  before do
    stub_address_search(
      postcode: "TE57 1NG",
      results: [
        {
          address: "123, Main Street, Springfield, TE57 1NG",
          address_line_1: "123",
          address_line_2: "Main Street",
          address_line_3: "Springfield",
          postcode: "TE57 1NG"
        }
      ]
    )
  end

  describe "#initialize" do
    context "when the address step is completed" do
      it "is valid" do
        session = create(
          :targeted_retention_incentive_payments_session,
          answers: {
            address_line_1: "123",
            address_line_2: "Main Street",
            address_line_3: "Springfield",
            postcode: "TE57 1NG"
          }
        )

        form = described_class.new(
          journey: Journeys::TargetedRetentionIncentivePayments,
          journey_session: session,
          params: ActionController::Parameters.new(claim: {})
        )

        expect(form).to be_valid
      end
    end
  end

  describe "#save" do
    let(:address) { "123, Main Street, Springfield, TE57 1NG" }
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
        skip_postcode_search: false,
        postcode: "TE57 1NG"
      )
    end
    let(:params) { ActionController::Parameters.new(claim: {address:}) }

    it "sets the address" do
      expect(form.save).to be true
      answers = journey_session.reload.answers
      expect(answers.address_line_1).to eq("123")
      expect(answers.address_line_2).to eq("Main Street")
      expect(answers.address_line_3).to eq("Springfield")
      expect(answers.postcode).to eq("TE57 1NG")
    end

    context "when the form is invalid" do
      let(:address) { nil }

      it "returns false" do
        expect(form.save).to be false
      end
    end

    context "when an address is already selected and no new selection is submitted" do
      let(:answers) do
        attributes_for(
          :"#{journey.i18n_namespace}_answers",
          skip_postcode_search: false,
          address_line_1: "123",
          address_line_2: "Main Street",
          address_line_3: "Springfield",
          postcode: "TE57 1NG"
        )
      end
      let(:params) { ActionController::Parameters.new(claim: {}) }

      it "is valid as the address is preselected in the ui" do
        expect(form.save).to be true
      end
    end
  end
end
