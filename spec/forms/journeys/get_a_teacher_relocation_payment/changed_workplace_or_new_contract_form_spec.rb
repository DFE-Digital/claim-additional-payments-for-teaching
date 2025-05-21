require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::ChangedWorkplaceOrNewContractForm, type: :model do
  let(:journey_session) { create(:get_a_teacher_relocation_payment_session) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        changed_workplace_or_new_contract: option
      }
    )
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::GetATeacherRelocationPayment,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    let(:option) { nil }

    it do
      is_expected.not_to(
        allow_value(nil)
        .for(:changed_workplace_or_new_contract)
        .with_message("Select yes if you have changed your workplace or started a new contract in the past year")
      )
    end
  end

  describe "#save" do
    context "selected yes" do
      let(:option) { true }

      it "updates the journey session" do
        expect { expect(form.save).to be(true) }.to(
          change { journey_session.reload.answers.changed_workplace_or_new_contract }
          .to(true)
        )
      end
    end

    context "selected no" do
      let(:option) { false }

      it "updates the journey session" do
        expect { expect(form.save).to be(true) }.to(
          change { journey_session.reload.answers.changed_workplace_or_new_contract }
          .to(false)
        )
      end
    end
  end
end
