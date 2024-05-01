require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::LeadershipPositionForm do
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }

  let(:eligibility) do
    create(
      :student_loans_eligibility,
      mostly_performed_leadership_duties: true,
      had_leadership_position: true
    )
  end

  let(:claim) do
    create(
      :claim,
      policy: Policies::StudentLoans,
      eligibility: eligibility
    )
  end

  let(:current_claim) { CurrentClaim.new(claims: [claim]) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {had_leadership_position: had_leadership_position}
    )
  end

  let(:form) do
    described_class.new(journey: journey, claim: current_claim, params: params)
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
        expect(eligibility.reload.had_leadership_position).to eq(true)
      end

      it "doesn't reset the mostly_performed_leadership_duties attribute" do
        expect(eligibility.reload.mostly_performed_leadership_duties).to eq(true)
      end
    end

    context "when the had_leadership_position attribute has changed" do
      let(:had_leadership_position) { false }

      it "updates the eligibility had_leadership_position attribute" do
        expect(eligibility.reload.had_leadership_position).to eq(false)
      end

      it "resets the mostly_performed_leadership_duties attribute" do
        expect(eligibility.reload.mostly_performed_leadership_duties).to eq(nil)
      end
    end
  end
end
