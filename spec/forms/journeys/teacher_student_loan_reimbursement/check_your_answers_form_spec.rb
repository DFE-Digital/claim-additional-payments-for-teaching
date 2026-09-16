require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::CheckYourAnswersForm do
  before do
    create(:journey_configuration, :student_loans, current_academic_year:)
  end

  let(:current_academic_year) { AcademicYear.new(2026) }
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:school) { create(:school) }

  let(:answers) {
    build(
      :student_loans_answers,
      :submittable
    )
  }

  let(:journey_session) { create(:student_loans_session, answers: answers) }

  subject do
    described_class.new(
      journey_session: journey_session,
      params: ActionController::Parameters.new(
        claim: {
          claimant_declaration: "1"
        }
      ),
      session: {},
      journey:
    )
  end

  describe "#save" do
    around do |example|
      freeze_time(Time.new(2026, 2, 11)) do
        example.run
      end
    end

    it "saves all answers into the claim and eligibility models" do
      subject.save

      claim = subject.claim

      expect(claim.policy).to eql(Policies::StudentLoans)
      expect(claim.read_attribute(:award_amount)).to eql(1000)
    end
  end
end
