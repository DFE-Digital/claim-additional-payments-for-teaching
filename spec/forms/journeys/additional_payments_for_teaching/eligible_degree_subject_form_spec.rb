require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::EligibleDegreeSubjectForm do
  subject(:form) do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }
  let(:journey_session) { create(:additional_payments_session) }
  let(:slug) { "eligible-degree-subject" }
  let(:params) { ActionController::Parameters.new({slug:, claim: claim_params}) }
  let(:claim_params) { {eligible_degree_subject: "true"} }

  describe "validations" do
    context "eligible_degree_subject" do
      it "cannot be nil" do
        form.eligible_degree_subject = nil

        expect(form).to be_invalid
        expect(form.errors[:eligible_degree_subject]).to eq([form.i18n_errors_path(:inclusion)])
      end

      it "can be true or false" do
        form.eligible_degree_subject = true
        expect(form).to be_valid

        form.eligible_degree_subject = false
        expect(form).to be_valid
      end
    end
  end

  describe "#save" do
    context "valid params" do
      let(:claim_params) { {eligible_degree_subject: "true"} }

      it "updates the attributes on the answers" do
        expect { form.save }.to(
          change { journey_session.answers.eligible_degree_subject }.to(true)
        )
      end
    end

    context "invalid params" do
      let(:claim_params) { {eligible_degree_subject: ""} }

      it "does not update the attributes on the claim (LUPP)" do
        expect { form.save }.to(
          not_change { journey_session.answers.eligible_degree_subject }
        )
      end
    end
  end
end
