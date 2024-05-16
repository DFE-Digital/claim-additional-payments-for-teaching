require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::SelectClaimSchoolForm, type: :model do
  before do
    create(
      :journey_configuration,
      :student_loans,
      current_academic_year: AcademicYear.new(2023)
    )
  end

  describe "#save" do
    subject(:save) { form.save }

    let(:claim) { CurrentClaim.new(claims: [create(:claim, policy: Policies::StudentLoans)]) }
    let(:journey) { Journeys::TeacherStudentLoanReimbursement }
    let(:journey_session) { build(:student_loans_session) }
    let(:params) { ActionController::Parameters.new }
    let(:form) { described_class.new(claim:, journey:, journey_session:, params:) }
    let!(:school) { create(:school, :eligible_for_journey, journey:) }

    context "when choosing a school" do
      let(:params) do
        ActionController::Parameters.new({
          claim: {
            claim_school_id: school.id
          }
        })
      end

      it "updates the claim with the correct school attributes" do
        expect { save }.to change { claim.reload.eligibility.claim_school_id }.to(school.id)
      end

      it "resets the somewhere_else attribute" do
        expect { save }.to change { claim.reload.eligibility.claim_school_somewhere_else }.to eq(false)
      end
    end

    context "with an existing school association and wants to change school" do
      let(:params) do
        ActionController::Parameters.new({
          claim: {
            claim_school_id: nil
          }
        })
      end

      before do
        claim.eligibility.update!(claim_school_id: school.id, claim_school_somewhere_else: false)
      end

      it "resets the school association" do
        expect { save }.to change { claim.reload.eligibility.claim_school_id }.to(nil)
      end

      it "resets the somewhere_else attribute" do
        expect { save }.to change { claim.reload.eligibility.claim_school_somewhere_else }.to eq(true)
      end
    end
  end
end
