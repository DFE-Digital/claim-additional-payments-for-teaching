require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::InductionCompletedForm do
  before {
    create(:journey_configuration, :additional_payments)
  }

  let(:slug) { "induction_completed" }

  let(:journey_session) { create(:additional_payments_session) }

  subject(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::AdditionalPaymentsForTeaching,
      params: params
    )
  end

  describe "#save" do
    let(:params) { ActionController::Parameters.new({slug: slug, claim: {induction_completed: true}}) }

    it "updates the induction_completed on the answers" do
      expect { expect(form.save).to be true }.to(
        change { journey_session.reload.answers.induction_completed }
          .from(nil).to(true)
      )
    end

    context "induction_completed missing" do
      let(:params) { ActionController::Parameters.new({slug: slug, claim: {induction_completed: ""}}) }

      it "does not save and adds error to form" do
        expect(form.save).to be false
        expect(form.errors[:induction_completed]).to eq ["Select yes if you have completed your induction"]
      end
    end
  end
end
