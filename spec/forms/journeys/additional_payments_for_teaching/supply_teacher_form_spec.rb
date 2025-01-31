require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::SupplyTeacherForm do
  before { create(:journey_configuration, :additional_payments) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }
  let(:journey_session) { build(:"#{journey::I18N_NAMESPACE}_session") }
  let(:slug) { "supply-teacher" }

  subject(:form) do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  describe "#employed_as_supply_teacher" do
    let(:params) { ActionController::Parameters.new({slug:, claim: {}}) }

    context "when answers is missing employed_as_supply_teacher" do
      it "returns nil" do
        expect(form.employed_as_supply_teacher).to be_nil
      end
    end

    context "when answers has employed_as_supply_teacher" do
      before do
        journey_session.answers.assign_attributes(employed_as_supply_teacher: true)
        journey_session.save!
      end

      it "returns existing value for employed_as_supply_teacher" do
        expect(form.employed_as_supply_teacher).to be_truthy
      end
    end
  end

  describe "#save" do
    context "when a valid employed_as_supply_teacher is submitted" do
      let(:params) { ActionController::Parameters.new({slug:, claim: {employed_as_supply_teacher: "Yes"}}) }

      before do
        journey_session.answers.assign_attributes(
          has_entire_term_contract: true,
          employed_directly: true
        )
        journey_session.save!
      end

      it "saves employed_as_supply_teacher on answers" do
        expect {
          form.save
        }.to change { journey_session.answers.employed_as_supply_teacher }.from(nil).to(true)
      end

      it "resets dependent attributes" do
        expect {
          form.save
        }.to change { journey_session.answers.has_entire_term_contract }.from(true).to(nil)
          .and change { journey_session.answers.employed_directly }.from(true).to(nil)
      end
    end

    context "when employed_as_supply_teacher is not provided" do
      let(:params) { ActionController::Parameters.new({slug:, claim: {employed_as_supply_teacher: nil}}) }

      it "does not save and adds error to form" do
        expect(form.save).to be false
        expect(form.errors[:employed_as_supply_teacher]).to eq ["Select yes if you are a supply teacher"]
      end
    end
  end
end
