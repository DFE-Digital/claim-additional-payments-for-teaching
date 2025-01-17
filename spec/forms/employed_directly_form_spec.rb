require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::EmployedDirectlyForm do
  before { create(:journey_configuration, :additional_payments) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:journey_session) { create(:additional_payments_session) }

  let(:slug) { "employed-directly" }

  subject(:form) do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  describe "#employed_directly" do
    let(:params) { ActionController::Parameters.new({slug:, claim: {}}) }

    context "when the journey session is missing employed_directly" do
      it "returns nil" do
        expect(form.employed_directly).to be_nil
      end
    end

    context "when journey session has employed_directly" do
      before do
        journey_session.answers.assign_attributes(employed_directly: true)
        journey_session.save
      end

      it "returns existing value for employed_directly" do
        expect(form.employed_directly).to be_truthy
      end
    end
  end

  describe "#save" do
    context "when a valid employed_directly is submitted" do
      let(:params) { ActionController::Parameters.new({slug:, claim: {employed_directly: "Yes"}}) }

      context "when claim eligibility is missing employed_directly" do
        it "saves employed_directly on the journey session" do
          expect { form.save }.to change { journey_session.reload.answers.employed_directly }.from(nil).to(true)
        end
      end

      context "when claim eligibility has employed_directly" do
        before do
          journey_session.answers.assign_attributes(employed_directly: false)
        end

        it "updates employed_directly on claim eligibility" do
          expect { form.save }.to change { journey_session.answers.employed_directly }.from(false).to(true)
        end
      end
    end

    context "when employed_directly is not provided" do
      let(:params) { ActionController::Parameters.new({slug:, claim: {employed_directly: nil}}) }

      it "does not save and adds error to form" do
        expect(form.save).to be false
        expect(form.errors[:employed_directly]).to eq ["Select yes if you are directly employed by your school"]
      end
    end
  end
end
