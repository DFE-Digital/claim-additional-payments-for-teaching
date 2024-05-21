require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::StillTeachingForm, type: :model do
  before { create(:journey_configuration, :student_loans) }

  let(:claim_school) { build(:school, :student_loans_eligible) }
  let(:eligibility) { create(:student_loans_eligibility, claim_school:, employment_status: nil) }
  let(:claim) { create(:claim, policy: Policies::StudentLoans, eligibility:) }
  let(:current_claim) { CurrentClaim.new(claims: [claim]) }
  let(:claim_params) { {} }
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:journey_session) do
    build(:journeys_session, journey: journey::ROUTING_NAME)
  end

  subject(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      claim: current_claim,
      params: ActionController::Parameters.new(claim: claim_params)
    )
  end

  describe "validations" do
    it do
      should validate_presence_of(:employment_status).with_message(
        "Select if you still work at #{claim_school.name}, another school or no longer teach in England"
      )
    end
  end

  describe "#error_message" do
    context "when the school is closed" do
      let(:claim_school) { build(:school, :student_loans_eligible, close_date: Date.yesterday) }

      it "does not contain the school name" do
        expect(form.error_message).to eq("Select yes if you are still employed to teach at a school in England")
      end
    end
  end

  describe "#save" do
    context "when no_school is submitted" do
      let(:claim_params) { {employment_status: "no_school"} }

      it "set the current_school_id to nil and saves employment status" do
        expect(form.save).to be true
        expect(claim.eligibility.current_school_id).to be_nil
        expect(claim.eligibility).to be_employed_at_no_school
      end
    end

    context "when different_school is submitted" do
      let(:claim_params) { {employment_status: "different_school"} }

      it "set the current_school_id to nil and saves employment status" do
        expect(form.save).to be true
        expect(claim.eligibility.current_school_id).to be_nil
        expect(claim.eligibility).to be_employed_at_different_school
      end
    end

    context "when suggested school is the claim_school (non-TID)" do
      let(:claim_params) { {current_school_id: claim_school.id, employment_status: "claim_school"} }

      it "set the current_school_id and saves employment status" do
        expect(form.save).to be true
        expect(claim.eligibility.current_school_id).to eq claim_school.id
        expect(claim.eligibility).to be_employed_at_claim_school
      end
    end

    context "when suggested school is from TPS (TID journey)" do
      let(:claim_params) { {current_school_id: claim_school.id, employment_status: "recent_tps_school"} }

      it "set the current_school_id and saves employment status" do
        expect(form.save).to be true
        expect(claim.eligibility.current_school_id).to eq claim_school.id
        expect(claim.eligibility).to be_employed_at_recent_tps_school
      end
    end
  end
end
