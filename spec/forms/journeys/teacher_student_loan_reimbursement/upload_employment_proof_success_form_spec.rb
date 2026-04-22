require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::UploadEmploymentProofSuccessForm do
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:journey_session) { create(:student_loans_session) }
  let(:params) { ActionController::Parameters.new }

  let(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: params
    )
  end

  describe "#save" do
    it { expect(form.save).to be true }
  end

  describe "#completed?" do
    context "when the step has been recorded" do
      before { journey_session.steps << "upload-employment-proof-success" }

      it { expect(form.completed?).to be true }
    end

    context "when the step has not been recorded" do
      it { expect(form.completed?).to be false }
    end
  end
end
