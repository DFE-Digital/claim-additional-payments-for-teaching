require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::StillTeachingForm, type: :model do
  before { create(:journey_configuration, :student_loans) }

  let(:claim_school) { create(:school, :student_loans_eligible) }
  let(:claim_params) { {} }
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:journey_session) do
    create(
      :student_loans_session,
      answers: {
        claim_school_id: claim_school.id,
        employment_status: nil
      }
    )
  end

  subject(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
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
      let(:claim_school) do
        create(:school, :student_loans_eligible, close_date: Date.yesterday)
      end

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
        expect(journey_session.answers.current_school_id).to be_nil
        expect(journey_session.answers.employed_at_no_school?).to be true
      end
    end

    context "when different_school is submitted" do
      let(:claim_params) { {employment_status: "different_school"} }

      it "set the current_school_id to nil and saves employment status" do
        expect(form.save).to be true
        expect(journey_session.answers.current_school_id).to be_nil
        expect(journey_session.answers.employed_at_different_school?).to be true
      end
    end

    context "when suggested school is the claim_school (non-TID)" do
      let(:claim_params) { {employment_status: "claim_school"} }

      it "set the current_school_id and saves employment status" do
        expect(form.save).to be true
        expect(journey_session.answers.current_school_id).to eq claim_school.id
        expect(journey_session.answers.employed_at_claim_school?).to be true
      end
    end

    context "when suggested school is from TPS (TID journey)" do
      let(:claim_params) { {employment_status: "recent_tps_school"} }

      it "set the current_school_id and saves employment status" do
        expect(form.save).to be true
        expect(journey_session.answers.current_school_id).to eq claim_school.id
        expect(journey_session.answers.employed_at_recent_tps_school?).to be true
      end
    end
  end
end
