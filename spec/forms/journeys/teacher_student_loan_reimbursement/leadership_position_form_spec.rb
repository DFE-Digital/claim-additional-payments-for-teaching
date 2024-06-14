require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::LeadershipPositionForm do
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }

  let(:journey_session) do
    create(
      :student_loans_session,
      answers: {
        had_leadership_position: true,
        mostly_performed_leadership_duties: true
      }
    )
  end

  let(:params) do
    ActionController::Parameters.new(
      claim: {had_leadership_position: had_leadership_position}
    )
  end

  let(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    describe "had_leadership_position" do
      context "when `true" do
        let(:had_leadership_position) { true }

        it { is_expected.to be_valid }
      end

      context "when `false`" do
        let(:had_leadership_position) { false }

        it { is_expected.to be_valid }
      end

      context "when `nil`" do
        let(:had_leadership_position) { nil }

        before { form.had_leadership_position = nil }

        it { is_expected.not_to be_valid }
      end
    end
  end

  describe "#save" do
    before { form.save }

    context "when the had_leadership_position attribute has not changed" do
      let(:had_leadership_position) { true }

      it "doesn't update the eligibility had_leadership_position attribute" do
        expect(
          journey_session.reload.answers.had_leadership_position
        ).to eq(true)
      end

      it "doesn't reset the mostly_performed_leadership_duties attribute" do
        expect(
          journey_session.reload.answers.mostly_performed_leadership_duties
        ).to eq(true)
      end
    end

    context "when the had_leadership_position attribute has changed" do
      let(:had_leadership_position) { false }

      it "updates the eligibility had_leadership_position attribute" do
        expect(
          journey_session.reload.answers.had_leadership_position
        ).to eq(false)
      end

      it "resets the mostly_performed_leadership_duties attribute" do
        expect(
          journey_session.reload.answers.mostly_performed_leadership_duties
        ).to eq(nil)
      end
    end
  end
end
