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
        claim_school_id: claim_school.id
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

  describe "#school" do
    it "returns the claim school" do
      expect(form.school).to eq claim_school
    end
  end

  describe "#radio_options" do
    context "when school is open" do
      it "returns three options including school name" do
        options = form.radio_options
        expect(options.size).to eq 3
        expect(options[0].id).to eq :claim_school
        expect(options[0].name).to eq "Yes, at #{claim_school.name}"
        expect(options[1].id).to eq :different_school
        expect(options[1].name).to eq "Yes, at another school"
        expect(options[2].id).to eq :no_school
        expect(options[2].name).to eq "No"
      end
    end

    context "when school is closed" do
      let(:claim_school) do
        create(:school, :student_loans_eligible, close_date: Date.yesterday)
      end

      it "returns two options without specific school option" do
        options = form.radio_options
        expect(options.size).to eq 2
        expect(options[0].id).to eq :different_school
        expect(options[0].name).to eq "Yes"
        expect(options[1].id).to eq :no_school
        expect(options[1].name).to eq "No"
      end
    end
  end

  describe "validations" do
    context "when the school is open" do
      it do
        is_expected.to validate_presence_of(:employment_status).with_message(
          "Select if you still work at #{claim_school.name}, " \
          "another school or no longer teach in England"
        )
      end
    end

    context "when the school is closed" do
      let(:claim_school) do
        create(:school, :student_loans_eligible, close_date: Date.yesterday)
      end

      it do
        is_expected.to validate_presence_of(:employment_status).with_message(
          "Select yes if you are still employed to teach at a school in England"
        )
      end
    end
  end

  describe "#save" do
    context "when no_school is submitted" do
      let(:claim_params) { {employment_status: "no_school"} }

      it "sets current_school_id to nil" do
        expect(form.save).to be true
        expect(journey_session.answers.current_school_id).to be_nil
        expect(journey_session.answers.employment_status).to eq "no_school"
      end
    end

    context "when different_school is submitted" do
      let(:claim_params) { {employment_status: "different_school"} }

      it "sets current_school_id to nil" do
        expect(form.save).to be true
        expect(journey_session.answers.current_school_id).to be_nil
        expect(journey_session.answers.employment_status).to eq "different_school"
      end
    end

    context "when claim_school is submitted and school is open" do
      let(:claim_params) { {employment_status: "claim_school"} }

      it "sets current_school_id to claim school id" do
        expect(form.save).to be true
        expect(journey_session.answers.current_school_id).to eq claim_school.id
        expect(journey_session.answers.employment_status).to eq "claim_school"
      end
    end

    context "when claim_school is submitted but school is closed" do
      let(:claim_school) do
        create(:school, :student_loans_eligible, close_date: Date.yesterday)
      end
      let(:claim_params) { {employment_status: "claim_school"} }

      it "sets current_school_id to nil" do
        expect(form.save).to be true
        expect(journey_session.answers.current_school_id).to be_nil
        expect(journey_session.answers.employment_status).to eq "claim_school"
      end
    end
  end
end
