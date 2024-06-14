require "rails_helper"

RSpec.describe Journeys::TeacherStudentLoanReimbursement::QtsYearForm, type: :model do
  subject(:form) do
    described_class.new(
      journey_session:,
      journey:,
      params:
    )
  end

  let(:journey) { Journeys::TeacherStudentLoanReimbursement }
  let(:journey_session) { create(:student_loans_session) }
  let(:slug) { "qts-year" }
  let(:params) { ActionController::Parameters.new({slug:, claim: claim_params}) }
  let(:claim_params) { {"qts_award_year" => "before_cut_off_date"} }

  it { is_expected.to be_a(Form) }

  describe "validations" do
    it do
      is_expected.to validate_presence_of(:qts_award_year)
        .with_message("Select when you completed your initial teacher training")
    end

    it do
      is_expected.to validate_inclusion_of(:qts_award_year)
        .in_array(["before_cut_off_date", "on_or_after_cut_off_date"])
        .with_message("Select when you completed your initial teacher training")
    end
  end

  describe "#save" do
    before do
      form.save
    end

    context "valid params" do
      let(:claim_params) { {"qts_award_year" => "before_cut_off_date"} }

      it "updates the answers" do
        expect(
          journey_session.reload.answers.qts_award_year
        ).to eq("before_cut_off_date")
      end
    end

    context "invalid params" do
      let(:claim_params) { {"qts_award_year" => "invalid_option"} }

      it "doesn't update the answers" do
        expect(
          journey_session.reload.answers.qts_award_year
        ).to be_nil
      end
    end
  end

  describe "#first_eligible_qts_award_year" do
    before do
      allow(Policies::StudentLoans).to receive(:first_eligible_qts_award_year)
        .and_return(AcademicYear.new("2023/2024"))
    end

    it { expect(form.first_eligible_qts_award_year).to eq("2023 to 2024") }
  end
end
