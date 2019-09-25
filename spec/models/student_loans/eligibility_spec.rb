# frozen_string_literal: true

require "rails_helper"

RSpec.describe StudentLoans::Eligibility, type: :model do
  describe "qts_award_year attribute" do
    it "rejects invalid values" do
      expect { StudentLoans::Eligibility.new(qts_award_year: "non-existence") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = StudentLoans::Eligibility.new(qts_award_year: "2013_2014")

      expect(eligibility.awarded_qualified_status_2013_2014?).to eq true
      expect(eligibility.awarded_qualified_status_before_2013?).to eq false
    end
  end

  describe "employment_status attribute" do
    it "rejects invalid values" do
      expect { StudentLoans::Eligibility.new(employment_status: "non-existence") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = StudentLoans::Eligibility.new(employment_status: :claim_school)

      expect(eligibility.employed_at_claim_school?).to eq true
      expect(eligibility.employed_at_different_school?).to eq false
    end
  end

  describe "student_loan_repayment_amount attribute" do
    it "validates that the loan repayment amount is numerical" do
      expect(StudentLoans::Eligibility.new(student_loan_repayment_amount: "don’t know")).not_to be_valid
      expect(StudentLoans::Eligibility.new(student_loan_repayment_amount: "£1,234.56")).to be_valid
    end

    it "validates that the loan repayment is under £99,999" do
      expect(StudentLoans::Eligibility.new(student_loan_repayment_amount: "100000000")).not_to be_valid
      expect(StudentLoans::Eligibility.new(student_loan_repayment_amount: "99999")).to be_valid
    end

    it "validates that the loan repayment a positive number" do
      expect(StudentLoans::Eligibility.new(student_loan_repayment_amount: "-99")).not_to be_valid
      expect(StudentLoans::Eligibility.new(student_loan_repayment_amount: "150")).to be_valid
    end
  end

  describe "#claim_school_name" do
    it "returns the name of the claim school" do
      eligibility = StudentLoans::Eligibility.new(claim_school: schools(:penistone_grammar_school))
      expect(eligibility.claim_school_name).to eq schools(:penistone_grammar_school).name
    end

    it "does not error if the claim school is not set" do
      expect(StudentLoans::Eligibility.new.claim_school_name).to be_nil
    end
  end

  describe "#current_school_name" do
    it "returns the name of the claim school" do
      claim = StudentLoans::Eligibility.new(current_school: schools(:penistone_grammar_school))
      expect(claim.current_school_name).to eq schools(:penistone_grammar_school).name
    end

    it "does not error if the claim school is not set" do
      expect(StudentLoans::Eligibility.new.current_school_name).to be_nil
    end
  end

  describe "#subjects_taught" do
    it "returns an array of the subject attributes that are true" do
      expect(StudentLoans::Eligibility.new.subjects_taught).to eq []
      expect(StudentLoans::Eligibility.new(biology_taught: true, physics_taught: true, chemistry_taught: false).subjects_taught).to eq [:biology_taught, :physics_taught]
    end
  end

  describe "#student_loan_repayment_amount=" do
    it "sets loan repayment amount with monetary characters stripped out" do
      eligibility = build(:student_loans_eligibility)
      eligibility.student_loan_repayment_amount = "£ 5,000.40"
      expect(eligibility.student_loan_repayment_amount).to eql(5000.40)
    end
  end

  describe "#ineligible?" do
    it "returns false when the eligibility cannot be determined" do
      expect(StudentLoans::Eligibility.new.ineligible?).to eql false
    end

    it "returns true when the qts_award_year is before 2013" do
      expect(StudentLoans::Eligibility.new(qts_award_year: "before_2013").ineligible?).to eql true
      expect(StudentLoans::Eligibility.new(qts_award_year: "2013_2014").ineligible?).to eql false
    end

    it "returns true when the claim_school is not eligible" do
      expect(StudentLoans::Eligibility.new(claim_school: schools(:hampstead_school)).ineligible?).to eql true
      expect(StudentLoans::Eligibility.new(claim_school: schools(:penistone_grammar_school)).ineligible?).to eql false
    end

    it "returns true when not currently teaching" do
      expect(StudentLoans::Eligibility.new(currently_teaching: false).ineligible?).to eql true
      expect(StudentLoans::Eligibility.new(currently_teaching: true).ineligible?).to eql false
    end

    it "returns true when not teaching an eligible subject" do
      expect(StudentLoans::Eligibility.new(taught_eligible_subjects: false).ineligible?).to eql true
      expect(StudentLoans::Eligibility.new(biology_taught: true).ineligible?).to eql false
    end

    it "returns true when more than half time is spent performing leadership duties" do
      expect(StudentLoans::Eligibility.new(mostly_performed_leadership_duties: true).ineligible?).to eql true
      expect(StudentLoans::Eligibility.new(mostly_performed_leadership_duties: false).ineligible?).to eql false
    end
  end

  describe "#ineligibility_reason" do
    it "returns nil when the reason for ineligibility cannot be determined" do
      expect(StudentLoans::Eligibility.new.ineligibility_reason).to be_nil
    end

    it "returns a symbol indicating the reason for ineligibility" do
      expect(StudentLoans::Eligibility.new(qts_award_year: "before_2013").ineligibility_reason).to eq :ineligible_qts_award_year
      expect(StudentLoans::Eligibility.new(claim_school: schools(:hampstead_school)).ineligibility_reason).to eq :ineligible_claim_school
      expect(StudentLoans::Eligibility.new(currently_teaching: false).ineligibility_reason).to eq :not_currently_teaching
      expect(StudentLoans::Eligibility.new(current_school: schools(:the_samuel_lister_academy)).ineligibility_reason).to eq :current_school_closed
      expect(StudentLoans::Eligibility.new(taught_eligible_subjects: false).ineligibility_reason).to eq :not_taught_eligible_subjects
      expect(StudentLoans::Eligibility.new(mostly_performed_leadership_duties: true).ineligibility_reason).to eq :not_taught_enough
    end
  end

  # Validation contexts
  context "when saving in the “qts-year” context" do
    it "is not valid without a value for qts_award_year" do
      expect(StudentLoans::Eligibility.new).not_to be_valid(:"qts-year")

      StudentLoans::Eligibility.qts_award_years.each_key do |academic_year|
        expect(StudentLoans::Eligibility.new(qts_award_year: academic_year)).to be_valid(:"qts-year")
      end
    end
  end

  context "when saving in the “currently-teaching” context" do
    it "validates the presence of currently_teaching" do
      expect(StudentLoans::Eligibility.new).not_to be_valid(:"currently-teaching")
      expect(StudentLoans::Eligibility.new(currently_teaching: false)).to be_valid(:"currently-teaching")
      expect(StudentLoans::Eligibility.new(currently_teaching: true)).to be_valid(:"currently-teaching")
    end
  end

  context "when saving in the “claim-school” context" do
    it "validates the presence of the claim_school" do
      expect(StudentLoans::Eligibility.new).not_to be_valid(:"claim-school")
      expect(StudentLoans::Eligibility.new(claim_school: schools(:penistone_grammar_school))).to be_valid(:"claim-school")
    end
  end

  context "when saving in the “where-teaching” context" do
    it "validates the presence of employment_status" do
      expect(StudentLoans::Eligibility.new).not_to be_valid(:"where-teaching")
      expect(StudentLoans::Eligibility.new(employment_status: :claim_school)).to be_valid(:"where-teaching")
    end
  end

  context "when saving in the “current-school” context" do
    it "validates the presence of the current_school" do
      expect(StudentLoans::Eligibility.new).not_to be_valid(:"current-school")
      expect(StudentLoans::Eligibility.new(current_school: schools(:hampstead_school))).to be_valid(:"current-school")
    end
  end

  context "when saving in the “subjects-taught” context" do
    it "is not valid if none of the subjects-taught attributes are true" do
      expect(StudentLoans::Eligibility.new).not_to be_valid(:"subjects-taught")
      expect(StudentLoans::Eligibility.new(biology_taught: false)).not_to be_valid(:"subjects-taught")
      expect(StudentLoans::Eligibility.new(biology_taught: false, physics_taught: false)).not_to be_valid(:"subjects-taught")
    end

    it "is valid when one or more of the subjects-taught attributes are true" do
      expect(StudentLoans::Eligibility.new(biology_taught: true)).to be_valid(:"subjects-taught")
      expect(StudentLoans::Eligibility.new(biology_taught: true, computer_science_taught: false)).to be_valid(:"subjects-taught")
      expect(StudentLoans::Eligibility.new(chemistry_taught: true, languages_taught: true)).to be_valid(:"subjects-taught")
    end

    it "is valid with no subjects present if taught_eligible_subjects is false" do
      expect(StudentLoans::Eligibility.new(taught_eligible_subjects: false)).to be_valid(:"subjects-taught")
      expect(StudentLoans::Eligibility.new(taught_eligible_subjects: true)).not_to be_valid(:"subjects-taught")
    end
  end

  context "when saving in the “leadership-position” context" do
    it "is not valid without a value for had_leadership_position" do
      expect(StudentLoans::Eligibility.new).not_to be_valid(:"leadership-position")
      expect(StudentLoans::Eligibility.new(had_leadership_position: true)).to be_valid(:"leadership-position")
      expect(StudentLoans::Eligibility.new(had_leadership_position: false)).to be_valid(:"leadership-position")
    end
  end

  context "when saving in the “mostly-performed-leadership-duties” context" do
    it "is valid when mostly_performed_leadership_duties is present as a boolean value and had_leadership_position is true" do
      expect(StudentLoans::Eligibility.new(had_leadership_position: true)).not_to be_valid(:"mostly-performed-leadership-duties")
      expect(StudentLoans::Eligibility.new(had_leadership_position: true, mostly_performed_leadership_duties: true)).to be_valid(:"mostly-performed-leadership-duties")
      expect(StudentLoans::Eligibility.new(had_leadership_position: true, mostly_performed_leadership_duties: false)).to be_valid(:"mostly-performed-leadership-duties")
    end

    it "is valid when missing if had_leadership_position is false" do
      expect(StudentLoans::Eligibility.new(had_leadership_position: false)).to be_valid(:"mostly-performed-leadership-duties")
    end
  end

  context "when saving in the “student-loan-amount” validation context" do
    it "validates the presence of student_loan_repayment_amount" do
      expect(StudentLoans::Eligibility.new).not_to be_valid(:"student-loan-amount")
      expect(StudentLoans::Eligibility.new(student_loan_repayment_amount: "£1,100")).to be_valid(:"student-loan-amount")
    end
  end

  context "when saving in the “submit” context" do
    it "is valid when all attributes are present" do
      expect(build(:student_loans_eligibility, :eligible)).to be_valid(:submit)
    end

    it "is not valid without a value for qts_award_year" do
      expect(build(:student_loans_eligibility, :eligible, qts_award_year: nil)).not_to be_valid(:submit)

      StudentLoans::Eligibility.qts_award_years.each_key do |academic_year|
        expect(build(:student_loans_eligibility, :eligible, qts_award_year: academic_year)).to be_valid(:submit)
      end
    end

    it "is not valid without a value for claim_school" do
      expect(build(:student_loans_eligibility, :eligible, claim_school: nil)).not_to be_valid(:submit)
    end

    it "is not valid without a value for employment_status" do
      expect(build(:student_loans_eligibility, :eligible, employment_status: nil)).not_to be_valid(:submit)
    end

    it "is not valid without a value for current_school" do
      expect(build(:student_loans_eligibility, :eligible, current_school: nil)).not_to be_valid(:submit)
    end

    it "is not valid without at least one subject being taught selected" do
      expect(build(:student_loans_eligibility, :eligible, physics_taught: nil)).not_to be_valid(:submit)
    end

    it "is not valid without a value for had_leadership_position" do
      expect(build(:student_loans_eligibility, :eligible, had_leadership_position: nil)).not_to be_valid(:submit)

      expect(build(:student_loans_eligibility, :eligible, had_leadership_position: true)).to be_valid(:submit)
      expect(build(:student_loans_eligibility, :eligible, had_leadership_position: false)).to be_valid(:submit)
    end

    it "is not valid without a value for mostly_performed_leadership_duties" do
      expect(build(:student_loans_eligibility, :eligible, mostly_performed_leadership_duties: nil)).not_to be_valid(:submit)
    end

    it "is not valid without a value for student_loan_repayment_amount" do
      expect(build(:student_loans_eligibility, student_loan_repayment_amount: nil)).not_to be_valid(:submit)
    end
  end
end
