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

  describe "#claim_school_name" do
    it "returns the name of the claim school" do
      claim = StudentLoans::Eligibility.new(claim_school: schools(:penistone_grammar_school))
      expect(claim.claim_school_name).to eq schools(:penistone_grammar_school).name
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

    it "returns true when no longer teaching" do
      expect(StudentLoans::Eligibility.new(employment_status: :no_school).ineligible?).to eql true
      expect(StudentLoans::Eligibility.new(employment_status: :claim_school).ineligible?).to eql false
    end

    it "returns true when less than half time is spent teaching eligible subjects" do
      expect(StudentLoans::Eligibility.new(mostly_teaching_eligible_subjects: false).ineligible?).to eql true
      expect(StudentLoans::Eligibility.new(mostly_teaching_eligible_subjects: true).ineligible?).to eql false
    end
  end

  describe "#ineligibility_reason" do
    it "returns nil when the reason for ineligibility cannot be determined" do
      expect(StudentLoans::Eligibility.new.ineligibility_reason).to be_nil
    end

    it "returns a symbol indicating the reason for ineligibility" do
      expect(StudentLoans::Eligibility.new(qts_award_year: "before_2013").ineligibility_reason).to eq :ineligible_qts_award_year
      expect(StudentLoans::Eligibility.new(claim_school: schools(:hampstead_school)).ineligibility_reason).to eq :ineligible_claim_school
      expect(StudentLoans::Eligibility.new(employment_status: :no_school).ineligibility_reason).to eq :employed_at_no_school
      expect(StudentLoans::Eligibility.new(mostly_teaching_eligible_subjects: false).ineligibility_reason).to eq :not_taught_eligible_subjects_enough
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

  context "when saving in the “claim-school” context" do
    it "validates the presence of the claim_school" do
      expect(StudentLoans::Eligibility.new).not_to be_valid(:"claim-school")
      expect(StudentLoans::Eligibility.new(claim_school: schools(:penistone_grammar_school))).to be_valid(:"claim-school")
    end
  end

  context "when saving in the “still-teaching” context" do
    it "validates the presence of employment_status" do
      expect(StudentLoans::Eligibility.new).not_to be_valid(:"still-teaching")
      expect(StudentLoans::Eligibility.new(employment_status: :claim_school)).to be_valid(:"still-teaching")
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

    it "validates when one or more of the subjects-taught attributes are true" do
      expect(StudentLoans::Eligibility.new(biology_taught: true)).to be_valid(:"subjects-taught")
      expect(StudentLoans::Eligibility.new(biology_taught: true, computer_science_taught: false)).to be_valid(:"subjects-taught")
      expect(StudentLoans::Eligibility.new(chemistry_taught: true, languages_taught: true)).to be_valid(:"subjects-taught")
    end

    it "is valid with no subjects present if mostly_teaching_eligible_subjects is false" do
      expect(StudentLoans::Eligibility.new(mostly_teaching_eligible_subjects: false)).to be_valid(:"subjects-taught")
      expect(StudentLoans::Eligibility.new(mostly_teaching_eligible_subjects: true)).not_to be_valid(:"subjects-taught")
    end
  end

  context "when saving in the “mostly-teaching-eligible-subjects” context" do
    it "is valid when mostly_teaching_eligible_subjects is present as a boolean value" do
      expect(StudentLoans::Eligibility.new).not_to be_valid(:"mostly-teaching-eligible-subjects")
      expect(StudentLoans::Eligibility.new(mostly_teaching_eligible_subjects: true)).to be_valid(:"mostly-teaching-eligible-subjects")
      expect(StudentLoans::Eligibility.new(mostly_teaching_eligible_subjects: false)).to be_valid(:"mostly-teaching-eligible-subjects")
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

    it "is not valid without a value for mostly_teaching_eligible_subjects" do
      expect(build(:student_loans_eligibility, :eligible, mostly_teaching_eligible_subjects: nil)).not_to be_valid(:submit)
    end
  end
end
