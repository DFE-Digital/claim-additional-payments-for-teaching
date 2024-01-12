require "rails_helper"

RSpec.describe StudentLoans::DqtRecord do
  let!(:policy_configuration) { create(:policy_configuration, :student_loans) }

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
      expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: Date.parse("15/8/2013")})).eligible_qts_award_date?).to eql false
    end

    context "in academic year 2029/30" do
      let!(:policy_configuration) { create(:policy_configuration, :student_loans, current_academic_year: "2029/2030") }

      it "returns false if the given QTS award date is not an eligible year" do
        expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: Date.parse("1/7/2018")})).eligible_qts_award_date?).to eql false
      end
    end

    it "returns false if the given QTS award date is blank" do
      expect(StudentLoans::DqtRecord.new(OpenStruct.new({qts_award_date: ""})).eligible_qts_award_date?).to eql false
    end
  end

  describe "#has_no_data_for_claim?" do
    subject(:dqt_record) { described_class.new(nil) }

    context "when one or more required data are present" do
      before { allow(dqt_record).to receive(:qts_award_date).and_return("test") }

      it { is_expected.not_to be_has_no_data_for_claim }
    end

    context "when all required data are not present" do
      before { allow(dqt_record).to receive(:qts_award_date).and_return(nil) }

      it { is_expected.to be_has_no_data_for_claim }
    end
  end
end
