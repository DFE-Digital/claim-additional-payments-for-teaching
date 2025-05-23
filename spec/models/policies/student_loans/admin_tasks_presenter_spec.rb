require "rails_helper"

RSpec.describe Policies::StudentLoans::AdminTasksPresenter, type: :model do
  let(:eligibility) { claim.eligibility }
  let(:claim) do
    build(:claim,
      academic_year: "2019/2020",
      student_loan_plan: StudentLoan::PLAN_1,
      eligibility: build(
        :student_loans_eligibility,
        :eligible,
        award_amount: "670.99",
        chemistry_taught: true,
        physics_taught: nil,
        languages_taught: true
      ))
  end
  subject(:presenter) { described_class.new(claim) }

  describe "#qualifications" do
    it "returns an array of label and values for displaying information for qualification checks" do
      expect(presenter.qualifications).to eq [["Award year", "Between the start of the 2013 to 2014 academic year and the end of the 2020 to 2021 academic year"]]
    end

    it "sets the “Award year” value based on the academic year the claim was made in" do
      claim.academic_year = "2030/2031"

      expected_qts_answer = presenter.qualifications[0][1]
      expect(expected_qts_answer).to eq "Between the start of the 2019 to 2020 academic year and the end of the 2020 to 2021 academic year"
    end
  end

  describe "#employment" do
    it "returns an array of label and values for displaying information for employment checks" do
      expect(presenter.employment).to eq [
        ["6 April 2018 to 5 April 2019", presenter.display_school(eligibility.claim_school)],
        [I18n.t("admin.current_school"), presenter.display_school(eligibility.current_school)]
      ]
    end
    it "correctly returns the expected string for financial year" do
      claim_2025 = build(:claim,
        academic_year: "2025/2026",
        student_loan_plan: StudentLoan::PLAN_1,
        eligibility: build(
          :student_loans_eligibility,
          :eligible,
          qts_award_year: "on_or_after_cut_off_date"
        ))
      presenter_2025 = described_class.new(claim_2025)
      expect(presenter_2025.employment[0][0]).to eq "6 April 2024 to 5 April 2025"
    end
  end

  describe "#student_loan_amount" do
    it "returns an array of label and values for displaying information for the student loan amount check" do
      expect(presenter.student_loan_amount).to eq [
        ["Student loan repayment amount", "£670.99"],
        ["Student loan plan", "Plan 1"]
      ]
    end
  end

  describe "#identity_confirmation" do
    it "returns an array of label and values for displaying information for the identity confirmation check" do
      expect(presenter.identity_confirmation).to eq [
        ["Current school", eligibility.current_school.name],
        ["Contact number", eligibility.current_school.phone_number]
      ]
    end
  end

  describe "#census_subjects_taught" do
    it "returns an array of label and values for displaying information for School Workforce Census checks" do
      expect(presenter.census_subjects_taught).to eq [
        ["Subjects taught", "Chemistry and Languages"]
      ]
    end
  end
end
