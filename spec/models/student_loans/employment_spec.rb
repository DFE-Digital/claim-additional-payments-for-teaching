# frozen_string_literal: true

require "rails_helper"

RSpec.describe StudentLoans::Employment, type: :model do
  let(:eligibility) { build(:student_loans_eligibility) }

  describe "school attribute" do
    it "validates that school is present" do
      expect(build(:student_loans_employment, school: nil, eligibility: eligibility)).not_to be_valid
      expect(build(:student_loans_employment, school: schools(:penistone_grammar_school), eligibility: eligibility)).to be_valid
    end
  end

  describe "student_loan_repayment_amount attribute" do
    it "validates that the loan repayment amount is numerical" do
      expect(build(:student_loans_employment, student_loan_repayment_amount: "don’t know", eligibility: eligibility)).not_to be_valid
      expect(build(:student_loans_employment, student_loan_repayment_amount: "£1,234.56", eligibility: eligibility)).to be_valid
    end

    it "validates that the loan repayment is under £99,999" do
      expect(build(:student_loans_employment, student_loan_repayment_amount: "100000000", eligibility: eligibility)).not_to be_valid
      expect(build(:student_loans_employment, student_loan_repayment_amount: "99999", eligibility: eligibility)).to be_valid
    end

    it "validates that the loan repayment a positive number" do
      expect(build(:student_loans_employment, student_loan_repayment_amount: "-99", eligibility: eligibility)).not_to be_valid
      expect(build(:student_loans_employment, student_loan_repayment_amount: "150", eligibility: eligibility)).to be_valid
    end
  end

  describe "#school_name" do
    it "returns the name of the school" do
      employment = build(:student_loans_employment, school: schools(:penistone_grammar_school), eligibility: eligibility)
      expect(employment.school_name).to eq schools(:penistone_grammar_school).name
    end
  end

  describe "#subjects_taught" do
    it "returns an array of the subject attributes that are true" do
      expect(build(:student_loans_employment, eligibility: eligibility).subjects_taught).to eq []
      expect(build(:student_loans_employment, biology_taught: true, physics_taught: true, chemistry_taught: false, eligibility: eligibility).subjects_taught).to eq [:biology_taught, :physics_taught]
    end
  end

  describe "#student_loan_repayment_amount=" do
    it "sets loan repayment amount with monetary characters stripped out" do
      employment = build(:student_loans_employment, eligibility: eligibility)
      employment.student_loan_repayment_amount = "£ 5,000.40"
      expect(employment.student_loan_repayment_amount).to eql(5000.40)
    end
  end

  describe "#ineligible?" do
    it "returns false when the eligibility cannot be determined" do
      expect(build(:student_loans_employment, eligibility: eligibility).ineligible?).to eql false
    end

    it "returns true when the school is not eligible" do
      expect(build(:student_loans_employment, school: schools(:hampstead_school), eligibility: eligibility).ineligible?).to eql true
      expect(build(:student_loans_employment, school: schools(:penistone_grammar_school), eligibility: eligibility).ineligible?).to eql false
    end

    it "returns true when not teaching an eligible subject" do
      expect(build(:student_loans_employment, taught_eligible_subjects: false, eligibility: eligibility).ineligible?).to eql true
      expect(build(:student_loans_employment, biology_taught: true, eligibility: eligibility).ineligible?).to eql false
    end
  end

  describe "#ineligibility_reason" do
    it "returns nil when the reason for ineligibility cannot be determined" do
      expect(build(:student_loans_employment, eligibility: eligibility).ineligibility_reason).to be_nil
    end

    it "returns a symbol indicating the reason for ineligibility" do
      expect(build(:student_loans_employment, school: schools(:hampstead_school), eligibility: eligibility).ineligibility_reason).to eq :ineligible_claim_school
      expect(build(:student_loans_employment, taught_eligible_subjects: false, eligibility: eligibility).ineligibility_reason).to eq :not_taught_eligible_subjects
    end
  end

  # Validation contexts
  context "when saving in the “subjects-taught” context" do
    it "is not valid if none of the subjects-taught attributes are true" do
      expect(build(:student_loans_employment, eligibility: eligibility)).not_to be_valid(:"subjects-taught")
      expect(build(:student_loans_employment, biology_taught: false, eligibility: eligibility)).not_to be_valid(:"subjects-taught")
      expect(build(:student_loans_employment, biology_taught: false, physics_taught: false, eligibility: eligibility)).not_to be_valid(:"subjects-taught")
    end

    it "is valid when one or more of the subjects-taught attributes are true" do
      expect(build(:student_loans_employment, biology_taught: true, eligibility: eligibility)).to be_valid(:"subjects-taught")
      expect(build(:student_loans_employment, biology_taught: true, computer_science_taught: false, eligibility: eligibility)).to be_valid(:"subjects-taught")
      expect(build(:student_loans_employment, chemistry_taught: true, languages_taught: true, eligibility: eligibility)).to be_valid(:"subjects-taught")
    end

    it "is valid with no subjects present if taught_eligible_subjects is false" do
      expect(build(:student_loans_employment, taught_eligible_subjects: false, eligibility: eligibility)).to be_valid(:"subjects-taught")
      expect(build(:student_loans_employment, taught_eligible_subjects: true, eligibility: eligibility)).not_to be_valid(:"subjects-taught")
    end
  end

  context "when saving in the “student-loan-amount” validation context" do
    it "validates the presence of student_loan_repayment_amount" do
      expect(build(:student_loans_employment, eligibility: eligibility)).not_to be_valid(:"student-loan-amount")
      expect(build(:student_loans_employment, student_loan_repayment_amount: "£1,100", eligibility: eligibility)).to be_valid(:"student-loan-amount")
    end
  end

  context "when saving in the “submit” context" do
    it "is valid when all attributes are present" do
      expect(build(:student_loans_employment, :eligible, eligibility: eligibility)).to be_valid(:submit)
    end

    it "is not valid without a value for school" do
      expect(build(:student_loans_employment, :eligible, school: nil, eligibility: eligibility)).not_to be_valid(:submit)
    end

    it "is not valid without at least one subject being taught selected" do
      expect(build(:student_loans_employment, :eligible, physics_taught: nil, eligibility: eligibility)).not_to be_valid(:submit)
    end

    it "is not valid without a value for student_loan_repayment_amount" do
      expect(build(:student_loans_employment, student_loan_repayment_amount: nil, eligibility: eligibility)).not_to be_valid(:submit)
    end
  end
end
