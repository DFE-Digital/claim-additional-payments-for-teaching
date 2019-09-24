# frozen_string_literal: true

require "rails_helper"

RSpec.describe StudentLoans::Eligibility, type: :model do
  describe "qts_award_year attribute" do
    it "rejects invalid values" do
      expect { build(:student_loans_eligibility, qts_award_year: "non-existence") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = build(:student_loans_eligibility, qts_award_year: "2013_2014")

      expect(eligibility.awarded_qualified_status_2013_2014?).to eq true
      expect(eligibility.awarded_qualified_status_before_2013?).to eq false
    end
  end

  describe "employment_status attribute" do
    it "rejects invalid values" do
      expect { build(:student_loans_eligibility, employment_status: "non-existence") }.to raise_error(ArgumentError)
    end

    it "has handily named boolean methods for the possible values" do
      eligibility = build(:student_loans_eligibility, employment_status: :claim_school)

      expect(eligibility.employed_at_claim_school?).to eq true
      expect(eligibility.employed_at_different_school?).to eq false
    end
  end

  describe "#current_school_name" do
    it "returns the name of the claim school" do
      claim = build(:student_loans_eligibility, current_school: schools(:penistone_grammar_school))
      expect(claim.current_school_name).to eq schools(:penistone_grammar_school).name
    end

    it "does not error if the claim school is not set" do
      expect(build(:student_loans_eligibility).current_school_name).to be_nil
    end
  end

  describe "#ineligible?" do
    it "returns false when the eligibility cannot be determined" do
      expect(build(:student_loans_eligibility).ineligible?).to eql false
    end

    it "returns true when the qts_award_year is before 2013" do
      expect(build(:student_loans_eligibility, qts_award_year: "before_2013").ineligible?).to eql true
      expect(build(:student_loans_eligibility, qts_award_year: "2013_2014").ineligible?).to eql false
    end

    it "returns true when no longer teaching" do
      expect(build(:student_loans_eligibility, employment_status: :no_school).ineligible?).to eql true
      expect(build(:student_loans_eligibility, employment_status: :claim_school).ineligible?).to eql false
    end

    it "returns true when current school is closed" do
      expect(build(:student_loans_eligibility, employment_status: :no_school).ineligible?).to eql true
      expect(build(:student_loans_eligibility, employment_status: :claim_school).ineligible?).to eql false
    end

    it "returns true when more than half time is spent performing leadership duties" do
      expect(build(:student_loans_eligibility, current_school: schools(:the_samuel_lister_academy)).ineligible?).to eql true
      expect(build(:student_loans_eligibility, current_school: schools(:penistone_grammar_school)).ineligible?).to eql false
    end

    it "returns true when the school is not eligible" do
      expect(build(:student_loans_eligibility, employments: [build(:student_loans_employment, school: schools(:hampstead_school))]).ineligible?).to eql true
      expect(build(:student_loans_eligibility, employments: [build(:student_loans_employment, school: schools(:penistone_grammar_school))]).ineligible?).to eql false
    end

    it "returns true when not teaching an eligible subject" do
      expect(build(:student_loans_eligibility, employments: [build(:student_loans_employment, taught_eligible_subjects: false)]).ineligible?).to eql true
      expect(build(:student_loans_eligibility, employments: [build(:student_loans_employment, biology_taught: true)]).ineligible?).to eql false
    end
  end

  describe "#ineligibility_reason" do
    it "returns nil when the reason for ineligibility cannot be determined" do
      expect(build(:student_loans_eligibility).ineligibility_reason).to be_nil
    end

    it "returns a symbol indicating the reason for ineligibility" do
      expect(build(:student_loans_eligibility, qts_award_year: "before_2013").ineligibility_reason).to eq :ineligible_qts_award_year
      expect(build(:student_loans_eligibility, employment_status: :no_school).ineligibility_reason).to eq :employed_at_no_school
      expect(build(:student_loans_eligibility, current_school: schools(:the_samuel_lister_academy)).ineligibility_reason).to eq :current_school_closed
      expect(build(:student_loans_eligibility, mostly_performed_leadership_duties: true).ineligibility_reason).to eq :not_taught_enough
      expect(build(:student_loans_eligibility, employments: [build(:student_loans_employment, school: schools(:hampstead_school))]).ineligibility_reason).to eq :ineligible_claim_school
      expect(build(:student_loans_eligibility, employments: [build(:student_loans_employment, taught_eligible_subjects: false)]).ineligibility_reason).to eq :not_taught_eligible_subjects
    end
  end

  # Validation contexts
  context "when saving in the “qts-year” context" do
    it "is not valid without a value for qts_award_year" do
      expect(build(:student_loans_eligibility)).not_to be_valid(:"qts-year")

      StudentLoans::Eligibility.qts_award_years.each_key do |academic_year|
        expect(build(:student_loans_eligibility, qts_award_year: academic_year)).to be_valid(:"qts-year")
      end
    end
  end

  context "when saving in the “still-teaching” context" do
    it "validates the presence of employment_status" do
      expect(build(:student_loans_eligibility)).not_to be_valid(:"still-teaching")
      expect(build(:student_loans_eligibility, employment_status: :claim_school)).to be_valid(:"still-teaching")
    end
  end

  context "when saving in the “current-school” context" do
    it "validates the presence of the current_school" do
      expect(build(:student_loans_eligibility)).not_to be_valid(:"current-school")
      expect(build(:student_loans_eligibility, current_school: schools(:hampstead_school))).to be_valid(:"current-school")
    end
  end

  context "when saving in the “leadership-position” context" do
    it "is not valid without a value for had_leadership_position" do
      expect(build(:student_loans_eligibility)).not_to be_valid(:"leadership-position")
      expect(build(:student_loans_eligibility, had_leadership_position: true)).to be_valid(:"leadership-position")
      expect(build(:student_loans_eligibility, had_leadership_position: false)).to be_valid(:"leadership-position")
    end
  end

  context "when saving in the “mostly-performed-leadership-duties” context" do
    it "is valid when mostly_performed_leadership_duties is present as a boolean value and had_leadership_position is true" do
      expect(build(:student_loans_eligibility, had_leadership_position: true)).not_to be_valid(:"mostly-performed-leadership-duties")
      expect(build(:student_loans_eligibility, had_leadership_position: true, mostly_performed_leadership_duties: true)).to be_valid(:"mostly-performed-leadership-duties")
      expect(build(:student_loans_eligibility, had_leadership_position: true, mostly_performed_leadership_duties: false)).to be_valid(:"mostly-performed-leadership-duties")
    end

    it "is valid when missing if had_leadership_position is false" do
      expect(build(:student_loans_eligibility, had_leadership_position: false)).to be_valid(:"mostly-performed-leadership-duties")
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

    it "is not valid without a value for employment_status" do
      expect(build(:student_loans_eligibility, :eligible, employment_status: nil)).not_to be_valid(:submit)
    end

    it "is not valid without a value for current_school" do
      expect(build(:student_loans_eligibility, :eligible, current_school: nil)).not_to be_valid(:submit)
    end

    it "is not valid without a value for had_leadership_position" do
      expect(build(:student_loans_eligibility, :eligible, had_leadership_position: nil)).not_to be_valid(:submit)

      expect(build(:student_loans_eligibility, :eligible, had_leadership_position: true)).to be_valid(:submit)
      expect(build(:student_loans_eligibility, :eligible, had_leadership_position: false)).to be_valid(:submit)
    end

    it "is not valid without a value for mostly_performed_leadership_duties" do
      expect(build(:student_loans_eligibility, :eligible, mostly_performed_leadership_duties: nil)).not_to be_valid(:submit)
    end
  end
end
