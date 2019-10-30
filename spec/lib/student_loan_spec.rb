require "rails_helper"

RSpec.describe StudentLoan do
  describe "#determine_plan" do
    it "always returns PLAN_1 for countries with a single student loan plan, i.e. Northern Ireland and Scotland" do
      expect(StudentLoan.determine_plan(StudentLoan::NORTHERN_IRELAND)).to eq StudentLoan::PLAN_1
      expect(StudentLoan.determine_plan(StudentLoan::SCOTLAND)).to eq StudentLoan::PLAN_1

      expect(StudentLoan.determine_plan(StudentLoan::SCOTLAND, StudentLoan::BEFORE_1_SEPT_2012)).to eq StudentLoan::PLAN_1
      expect(StudentLoan.determine_plan(StudentLoan::SCOTLAND, StudentLoan::ON_OR_AFTER_1_SEPT_2012)).to eq StudentLoan::PLAN_1
    end

    it "returns PLAN_1 when the course(s) started before 1 September 2012" do
      expect(StudentLoan.determine_plan(StudentLoan::ENGLAND, StudentLoan::BEFORE_1_SEPT_2012)).to eq StudentLoan::PLAN_1
    end

    it "returns PLAN_2 when the course(s) started on or after 1 September 2012" do
      expect(StudentLoan.determine_plan(StudentLoan::ENGLAND, StudentLoan::ON_OR_AFTER_1_SEPT_2012)).to eq StudentLoan::PLAN_2
    end

    it "returns PLAN_1_AND_2 when courses started both before and after 1 September 2012" do
      expect(StudentLoan.determine_plan(StudentLoan::ENGLAND, StudentLoan::BEFORE_AND_AFTER_1_SEPT_2012)).to eq StudentLoan::PLAN_1_AND_2
    end
  end
end
