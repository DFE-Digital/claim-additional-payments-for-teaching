require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::SubjectsTaughtForm, type: :model do
  subject(:form) do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  let(:claim_school) { create(:school, name: "test school") }

  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:journey_session) do
    create(
      :student_loans_session,
      answers: {
        claim_school_id: claim_school.id
      }
    )
  end
  let(:slug) { "subjects-taught" }
  let(:params) { ActionController::Parameters.new({slug:, claim: claim_params}) }
  let(:claim_params) { {"subjects_taught" => ["biology_taught"]} }

  it { is_expected.to be_a(Form) }

  describe "validations" do
    context "when no options are selected" do
      let(:claim_params) { {"subjects_taught" => [""]} }

      it do
        aggregate_failures do
          is_expected.not_to be_valid
          expect(form.errors[:subjects_taught]).to eq([form.i18n_errors_path(:select_subject)])
        end
      end
    end

    context "when one or more subjects are selected" do
      let(:claim_params) { {"subjects_taught" => ["", "biology_taught", "chemistry_taught"]} }

      it { is_expected.to be_valid }
    end

    context "when 'I did not teach any of these subjects' is selected" do
      let(:claim_params) { {"subjects_taught" => ["", "none_taught"]} }

      it { is_expected.to be_valid }
    end
  end

  describe "#save" do
    before { form.save }

    context "valid params" do
      context "when multiple subject are selected" do
        let(:claim_params) { {"subjects_taught" => ["", "biology_taught", "chemistry_taught"]} }

        it "updates the answers" do
          journey_session.reload

          answers = journey_session.answers

          expect(answers.biology_taught).to eq(true)
          expect(answers.chemistry_taught).to eq(true)
          expect(answers.physics_taught).to eq(false)
          expect(answers.computing_taught).to eq(false)
          expect(answers.languages_taught).to eq(false)
          expect(answers.taught_eligible_subjects).to eq(true)
        end
      end

      context "when no subjects are selected" do
        let(:claim_params) { {"subjects_taught" => ["", "none_taught"]} }

        it "updates the answers" do
          journey_session.reload

          answers = journey_session.answers

          expect(answers.biology_taught).to eq(false)
          expect(answers.chemistry_taught).to eq(false)
          expect(answers.physics_taught).to eq(false)
          expect(answers.computing_taught).to eq(false)
          expect(answers.languages_taught).to eq(false)
          expect(answers.taught_eligible_subjects).to eq(false)
        end
      end
    end

    context "invalid params" do
      let(:claim_params) { {"subjects_taught" => []} }

      it "doesn't update the answers" do
        expect { form.save }.to(
          not_change { journey_session.reload.answers.attributes }
        )
      end
    end
  end

  describe "#claim_school_name" do
    subject { form.claim_school_name }

    it { is_expected.to eq("test school") }
  end
end
