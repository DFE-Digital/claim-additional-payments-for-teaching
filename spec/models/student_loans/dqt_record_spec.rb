require "rails_helper"

RSpec.describe StudentLoans::DqtRecord do
  describe "#eligble?" do
    it "returns true if the given QTS award date is after the first eligible academic year" do
      expect(StudentLoans::DqtRecord.new({qts_date: Date.parse("19/3/2017")}).eligible?).to eql true
    end

    it "returns true if the given QTS award date is in the first eligible academic year" do
      expect(StudentLoans::DqtRecord.new({qts_date: Date.parse("1/10/2014")}).eligible?).to eql true
    end

    it "returns false if the given QTS award date is not an eligible year" do
      expect(StudentLoans::DqtRecord.new({qts_date: Date.parse("8/3/2000")}).eligible?).to eql false
    end

    it "returns false if the given QTS award date is blank" do
      expect(StudentLoans::DqtRecord.new({qts_date: ""}).eligible?).to eql false
    end
  end

  describe "#eligible_qts_date?" do
    it "returns true if the given QTS award date is after the first eligible academic year" do
      expect(StudentLoans::DqtRecord.new({qts_date: Date.parse("19/3/2017")}).eligible_qts_date?).to eql true
    end

    it "returns true if the given QTS award date is in the first eligible academic year" do
      expect(StudentLoans::DqtRecord.new({qts_date: Date.parse("1/10/2014")}).eligible_qts_date?).to eql true
    end

    it "returns false if the given QTS award date is not an eligible year" do
      expect(StudentLoans::DqtRecord.new({qts_date: Date.parse("8/3/2000")}).eligible_qts_date?).to eql false
    end

    it "returns false if the given QTS award date is blank" do
      expect(StudentLoans::DqtRecord.new({qts_date: ""}).eligible_qts_date?).to eql false
    end
  end

  describe "#eligible_qualification_subject?" do
    it "returns true" do
      expect(StudentLoans::DqtRecord.new({qts_date: Date.parse("19/3/2017")}).eligible_qualification_subject?).to eql true
    end

    context "without subject codes" do
      it "returns false" do
        expect(StudentLoans::DqtRecord.new({qts_date: Date.parse("19/3/2017"), degree_codes: [], itt_subject_codes: []}).eligible_qualification_subject?).to eql false
      end
    end
  end
end
