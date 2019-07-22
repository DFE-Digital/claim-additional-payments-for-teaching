require "rails_helper"
require "student_loans"

RSpec.describe StudentLoans do
  describe "#determine_plan" do
    it "always returns PLAN_1 for countries with a single student loan plan, i.e. Northern Ireland and Scotland" do
      expect(StudentLoans.determine_plan(StudentLoans::NORTHERN_IRELAND)).to eq StudentLoans::PLAN_1
      expect(StudentLoans.determine_plan(StudentLoans::SCOTLAND)).to eq StudentLoans::PLAN_1

      expect(StudentLoans.determine_plan(StudentLoans::SCOTLAND, StudentLoans::BEFORE_1_SEPT_2012)).to eq StudentLoans::PLAN_1
      expect(StudentLoans.determine_plan(StudentLoans::SCOTLAND, StudentLoans::ON_OR_AFTER_1_SEPT_2012)).to eq StudentLoans::PLAN_1
    end

    it "returns PLAN_1 when the course(s) started before 1 September 2012" do
      expect(StudentLoans.determine_plan(StudentLoans::ENGLAND, StudentLoans::BEFORE_1_SEPT_2012)).to eq StudentLoans::PLAN_1
    end

    it "returns PLAN_2 when the course(s) started on or after 1 Semptember 2012" do
      expect(StudentLoans.determine_plan(StudentLoans::ENGLAND, StudentLoans::ON_OR_AFTER_1_SEPT_2012)).to eq StudentLoans::PLAN_2
    end

    it "returns PLAN_1_AND_2 when courses started both before and after 1st Semptember 2012" do
      expect(StudentLoans.determine_plan(StudentLoans::ENGLAND, StudentLoans::BEFORE_AND_AFTER_1_SEPT_2012)).to eq StudentLoans::PLAN_1_AND_2
    end
  end
end
