require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::StillTeachingTpsForm, type: :model do
  before { create(:journey_configuration, :student_loans) }

  let(:recent_tps_school) { create(:school, :student_loans_eligible) }
  let(:claim_params) { {} }
  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:journey_session) do
    create(
      :student_loans_session,
      answers: {
        teacher_id_user_info: {
          trn: "1234567"
        }
      }
    )
  end

  before do
    create(
      :teachers_pensions_service,
      teacher_reference_number: "1234567",
      school_urn: recent_tps_school.establishment_number,
      la_urn: recent_tps_school.local_authority.code,
      start_date: 1.month.ago,
      end_date: 1.day.ago
    )
  end

  subject(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: ActionController::Parameters.new(claim: claim_params)
    )
  end

  describe "#school" do
    it "returns the recent TPS school" do
      expect(form.school).to eq recent_tps_school
    end
  end

  describe "validations" do
    it do
      is_expected.to validate_presence_of(:employment_status).with_message(
        "Select if you still work at #{recent_tps_school.name}, another " \
        "school or no longer teach in England"
      )
    end
  end

  describe "#save" do
    context "when no_school is submitted" do
      let(:claim_params) { {employment_status: "no_school"} }

      it "saves employment_status and sets current_school_id to nil" do
        expect(form.save).to be true
        expect(journey_session.answers.current_school_id).to be_nil
        expect(journey_session.answers.employment_status).to eq "no_school"
      end
    end

    context "when different_school is submitted" do
      let(:claim_params) { {employment_status: "different_school"} }

      it "saves employment_status and sets current_school_id to nil" do
        expect(form.save).to be true
        expect(journey_session.answers.current_school_id).to be_nil
        expect(journey_session.answers.employment_status).to eq "different_school"
      end
    end

    context "when recent_tps_school is submitted" do
      let(:claim_params) { {employment_status: "recent_tps_school"} }

      it "saves employment_status and sets current_school_id to TPS school id" do
        expect(form.save).to be true
        expect(journey_session.answers.current_school_id).to eq recent_tps_school.id
        expect(journey_session.answers.employment_status).to eq "recent_tps_school"
      end
    end

    context "when claim_school is submitted" do
      let(:claim_params) { {employment_status: "claim_school"} }

      it "saves employment_status and sets current_school_id to TPS school id" do
        expect(form.save).to be true
        expect(journey_session.answers.current_school_id).to eq recent_tps_school.id
        expect(journey_session.answers.employment_status).to eq "claim_school"
      end
    end
  end
end
