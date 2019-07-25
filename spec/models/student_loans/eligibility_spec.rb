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

  # Validation contexts
  context "when saving in the “qts-year” context" do
    it "is not valid without a value for qts_award_year" do
      expect(StudentLoans::Eligibility.new).not_to be_valid(:"qts-year")

      StudentLoans::Eligibility.qts_award_years.each_key do |academic_year|
        expect(StudentLoans::Eligibility.new(qts_award_year: academic_year)).to be_valid(:"qts-year")
      end
    end
  end

  context "when saving in the “submit” context" do
    it "is not valid without a value for qts_award_year" do
      expect(StudentLoans::Eligibility.new).not_to be_valid(:submit)

      StudentLoans::Eligibility.qts_award_years.each_key do |academic_year|
        expect(StudentLoans::Eligibility.new(qts_award_year: academic_year)).to be_valid(:submit)
      end
    end
  end
end
