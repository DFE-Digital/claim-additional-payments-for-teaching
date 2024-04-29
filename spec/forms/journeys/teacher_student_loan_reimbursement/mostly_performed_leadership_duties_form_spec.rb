require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::MostlyPerformedLeadershipDutiesForm do
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
      claim: {
        mostly_performed_leadership_duties: mostly_performed_leadership_duties
      }
    )
  end

  let(:form) do
    described_class.new(journey: journey, claim: current_claim, params: params)
  end

  describe "validations" do
    subject { form }

    context "when `true`" do
      let(:mostly_performed_leadership_duties) { true }

      it { is_expected.to be_valid }
    end

    context "when `false`" do
      let(:mostly_performed_leadership_duties) { false }

      it { is_expected.to be_valid }
    end

    context "when `nil`" do
      let(:mostly_performed_leadership_duties) { nil }

      before { form.mostly_performed_leadership_duties = nil }

      it { is_expected.not_to be_valid }
    end
  end

  describe "#save" do
    before { form.save }

    let(:mostly_performed_leadership_duties) { true }

    it "updates the eligibility with the mostly_performed_leadership_duties" do
      expect(eligibility.mostly_performed_leadership_duties).to(
        eq(true)
      )
    end
  end
end
