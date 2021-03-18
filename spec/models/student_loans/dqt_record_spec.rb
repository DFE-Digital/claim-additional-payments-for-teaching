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
end
