require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::BreaksInEmploymentForm do
  let(:journey_session) { create(:get_a_teacher_relocation_payment_session) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {}
    )
  end

  subject do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::GetATeacherRelocationPayment,
      params: params
    )
  end

  describe "validations" do
    describe "#breaks_in_employment" do
      it "must be present" do
        expect(subject).to be_invalid
        expect(subject.errors[:breaks_in_employment]).to eql(["Select yes if you have had any breaks in employment over the past year"])
      end
    end
  end

  describe "#save" do
    context "when form is invalid" do
      it "returns false" do
        expect(subject.save).to be_falsey
      end
    end

    context "when form is valid" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {
            breaks_in_employment: "true"
          }
        )
      end

      it "returns true" do
        expect(subject.save).to be_truthy
      end

      it "persists answers" do
        expect {
          subject.save
        }.to change { journey_session.reload.answers.breaks_in_employment }.from(nil).to(true)
      end
    end
  end
end
