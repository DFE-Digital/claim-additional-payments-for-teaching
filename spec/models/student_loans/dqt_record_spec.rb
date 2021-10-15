require "rails_helper"

RSpec.describe StudentLoans::DqtRecord do
  describe "#eligble?" do
    it "returns true if the given QTS award date is after the first eligible academic year" do
      expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: Date.parse("19/3/2017")})).eligible?).to eql true
    end

    it "returns true if the given QTS award date is in the first eligible academic year" do
      expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: Date.parse("1/10/2014")})).eligible?).to eql true
    end

    it "returns false if the given QTS award date is not an eligible year" do
      expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: Date.parse("8/3/2000")})).eligible?).to eql false
    end

    it "returns false if the given QTS award date is blank" do
      expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: ""})).eligible?).to eql false
    end
  end

  describe "#eligible_qts_award_date?" do
    it "returns true if the given QTS award date is after the first eligible academic year" do
      expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: Date.parse("19/3/2017")})).eligible_qts_award_date?).to eql true
    end

    it "returns true if the given QTS award date is in the first eligible academic year" do
      expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: Date.parse("1/10/2014")})).eligible_qts_award_date?).to eql true
    end

    it "returns false if the given QTS award date is not an eligible year" do
      expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: Date.parse("8/3/2000")})).eligible_qts_award_date?).to eql false
    end

    it "returns false if the given QTS award date is not an eligible year" do
      expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: Date.parse("15/9/2013")})).eligible_qts_award_date?).to eql false
    end

    context "in academic year 2029/30" do
      before do
        @existing_config = PolicyConfiguration.for(StudentLoans).current_academic_year
        PolicyConfiguration.for(StudentLoans).update(current_academic_year: "2029/2030")
      end

      after do
        PolicyConfiguration.for(StudentLoans).update(current_academic_year: @existing_config)
      end

      it "returns false if the given QTS award date is not an eligible year" do
        expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: Date.parse("1/7/2018")})).eligible_qts_award_date?).to eql false
      end
    end

    it "returns false if the given QTS award date is blank" do
      expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: ""})).eligible_qts_award_date?).to eql false
    end
  end

  describe "#eligible_qualification_subject?" do
    it "returns true" do
      expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: Date.parse("19/3/2017"), degree_codes: ["ANY"], itt_subject_codes: ["ANY"]})).eligible_qualification_subject?).to eql true
    end

    context "without subject codes" do
      it "returns false" do
        expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: Date.parse("19/3/2017"), degree_codes: [], itt_subject_codes: []})).eligible_qualification_subject?).to eql false
      end
    end
  end
end
