require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::SubjectsTaughtForm, type: :model do
  subject(:form) do
    described_class.new(claim:, journey_session:, journey:, params:)
  end

  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:journey_session) do
    build(:journeys_session, journey: journey::ROUTING_NAME)
  end
  let(:claim) { CurrentClaim.new(claims: [build(:claim, policy: Policies::StudentLoans)]) }
  let(:slug) { "subjects-taught" }
  let(:params) { ActionController::Parameters.new({slug:, claim: claim_params}) }
  let(:claim_params) { {"subjects_taught" => ["biology_taught"]} }

  it { is_expected.to be_a(Form) }

  describe "validations" do
    context "when no options are selected" do
      let(:claim_params) { {"subjects_taught" => []} }

      it do
        aggregate_failures do
          is_expected.not_to be_valid
          expect(form.errors[:subjects_taught]).to eq([form.i18n_errors_path(:select_subject)])
        end
      end
    end

    context "when one or more subjects are selected" do
      let(:claim_params) { {"subjects_taught" => ["biology_taught", "chemistry_taught"]} }

      it { is_expected.to be_valid }
    end

    context "when 'I did not teach any of these subjects' is selected" do
      let(:claim_params) { {"subjects_taught" => ["none_taught"]} }

      it { is_expected.to be_valid }
    end
  end

  describe "#save" do
    before do
      allow(form).to receive(:update!)
      form.save
    end

    context "valid params" do
      context "when multiple subject are selected" do
        let(:claim_params) { {"subjects_taught" => ["biology_taught", "chemistry_taught"]} }
        let(:expected_saved_attributes) do
          {
            eligibility_attributes: {
              "biology_taught" => true,
              "chemistry_taught" => true,
              "physics_taught" => false,
              "computing_taught" => false,
              "languages_taught" => false,
              "taught_eligible_subjects" => true
            }
          }
        end

        it { is_expected.to have_received(:update!).with(expected_saved_attributes) }
      end

      context "when no subjects are selected" do
        let(:claim_params) { {"subjects_taught" => ["none_taught"]} }
        let(:expected_saved_attributes) do
          {
            eligibility_attributes: {
              "biology_taught" => false,
              "chemistry_taught" => false,
              "physics_taught" => false,
              "computing_taught" => false,
              "languages_taught" => false,
              "taught_eligible_subjects" => false
            }
          }
        end

        it { is_expected.to have_received(:update!).with(expected_saved_attributes) }
      end
    end

    context "invalid params" do
      let(:claim_params) { {"subjects_taught" => []} }

      it { expect(form).not_to have_received(:update!) }
    end
  end

  describe "#claim_school_name" do
    before do
      allow(claim).to receive(:eligibility).and_return(double(claim_school_name: "test school"))
    end

    it { expect(form.claim_school_name).to eq("test school") }
  end

  describe "#subject_attributes" do
    it { expect(form.subject_attributes).to eq(Policies::StudentLoans::Eligibility::SUBJECT_ATTRIBUTES) }
  end

  describe "#subject_taught_selected?" do
    context "when the subject is invalid" do
      it { expect(form.subject_taught_selected?(:invalid_subject_taught)).to be_nil }
    end

    context "when the subject is taught" do
      before do
        claim.eligibility.biology_taught = true
      end

      it { expect(form.subject_taught_selected?(:biology_taught)).to eq(true) }
    end

    context "when the subject is not taught" do
      before do
        claim.eligibility.biology_taught = false
      end

      it { expect(form.subject_taught_selected?(:biology_taught)).to eq(false) }
    end
  end
end
