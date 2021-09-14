require "rails_helper"

RSpec.describe StudentLoan do
  describe "#determine_plan" do
    context "with no student loan and no posgraduate masters and/or postgraduate doctoral loan(s)" do
      it "returns Claim::NO_STUDENT_LOAN" do
        expect(StudentLoan.determine_plan(false, false)).to eq Claim::NO_STUDENT_LOAN
      end
    end

    context "with student loan" do
      context "with no postgraduate masters or doctoral loan(s)" do
        it "always returns PLAN_1 for countries with a single student loan plan, i.e. Northern Ireland" do
          expect(StudentLoan.determine_plan(true, false, StudentLoan::NORTHERN_IRELAND)).to eq StudentLoan::PLAN_1

          expect(StudentLoan.determine_plan(true, false, StudentLoan::NORTHERN_IRELAND, StudentLoan::BEFORE_1_SEPT_2012)).to eq StudentLoan::PLAN_1
          expect(StudentLoan.determine_plan(true, false, StudentLoan::NORTHERN_IRELAND, StudentLoan::ON_OR_AFTER_1_SEPT_2012)).to eq StudentLoan::PLAN_1
        end

        it "returns PLAN_1 when the course(s) started before 1 September 2012" do
          expect(StudentLoan.determine_plan(true, false, StudentLoan::ENGLAND, StudentLoan::BEFORE_1_SEPT_2012)).to eq StudentLoan::PLAN_1
          expect(StudentLoan.determine_plan(true, false, StudentLoan::WALES, StudentLoan::BEFORE_1_SEPT_2012)).to eq StudentLoan::PLAN_1
        end

        it "returns PLAN_2 when the course(s) started on or after 1 September 2012" do
          expect(StudentLoan.determine_plan(true, false, StudentLoan::ENGLAND, StudentLoan::ON_OR_AFTER_1_SEPT_2012)).to eq StudentLoan::PLAN_2
          expect(StudentLoan.determine_plan(true, false, StudentLoan::WALES, StudentLoan::ON_OR_AFTER_1_SEPT_2012)).to eq StudentLoan::PLAN_2
        end

        it "returns PLAN_1_AND_2 when courses started both before and after 1 September 2012" do
          expect(StudentLoan.determine_plan(true, false, StudentLoan::ENGLAND, StudentLoan::BEFORE_AND_AFTER_1_SEPT_2012)).to eq StudentLoan::PLAN_1_AND_2
        end

        it "returns PLAN_4 when the country is Scotland" do
          expect(StudentLoan.determine_plan(true, false, StudentLoan::SCOTLAND)).to eq StudentLoan::PLAN_4

          expect(StudentLoan.determine_plan(true, false, StudentLoan::SCOTLAND, StudentLoan::BEFORE_1_SEPT_2012)).to eq StudentLoan::PLAN_4
          expect(StudentLoan.determine_plan(true, false, StudentLoan::SCOTLAND, StudentLoan::ON_OR_AFTER_1_SEPT_2012)).to eq StudentLoan::PLAN_4
        end
      end

      context "with postgraduate masters or doctoral loan(s)" do
        it "always returns PLAN_1_AND_3 for countries with a single student loan plan, i.e. Northern Ireland" do
          expect(StudentLoan.determine_plan(true, true, StudentLoan::NORTHERN_IRELAND)).to eq StudentLoan::PLAN_1_AND_3

          expect(StudentLoan.determine_plan(true, true, StudentLoan::NORTHERN_IRELAND, StudentLoan::BEFORE_1_SEPT_2012)).to eq StudentLoan::PLAN_1_AND_3
          expect(StudentLoan.determine_plan(true, true, StudentLoan::NORTHERN_IRELAND, StudentLoan::ON_OR_AFTER_1_SEPT_2012)).to eq StudentLoan::PLAN_1_AND_3
        end

        it "returns PLAN_1_AND_3 when the course(s) started before 1 September 2012" do
          expect(StudentLoan.determine_plan(true, true, StudentLoan::ENGLAND, StudentLoan::BEFORE_1_SEPT_2012)).to eq StudentLoan::PLAN_1_AND_3
          expect(StudentLoan.determine_plan(true, true, StudentLoan::WALES, StudentLoan::BEFORE_1_SEPT_2012)).to eq StudentLoan::PLAN_1_AND_3
        end

        it "returns PLAN_2_AND_3 when the course(s) started on or after 1 September 2012" do
          expect(StudentLoan.determine_plan(true, true, StudentLoan::ENGLAND, StudentLoan::ON_OR_AFTER_1_SEPT_2012)).to eq StudentLoan::PLAN_2_AND_3
          expect(StudentLoan.determine_plan(true, true, StudentLoan::WALES, StudentLoan::ON_OR_AFTER_1_SEPT_2012)).to eq StudentLoan::PLAN_2_AND_3
        end

        it "returns PLAN_1_AND_2_AND_3 when courses started both before and after 1 September 2012" do
          expect(StudentLoan.determine_plan(true, true, StudentLoan::ENGLAND, StudentLoan::BEFORE_AND_AFTER_1_SEPT_2012)).to eq StudentLoan::PLAN_1_AND_2_AND_3
        end

        it "returns PLAN_4_AND_3 when the country is Scotland" do
          expect(StudentLoan.determine_plan(true, true, StudentLoan::SCOTLAND)).to eq StudentLoan::PLAN_4_AND_3

          expect(StudentLoan.determine_plan(true, true, StudentLoan::SCOTLAND, StudentLoan::BEFORE_1_SEPT_2012)).to eq StudentLoan::PLAN_4_AND_3
          expect(StudentLoan.determine_plan(true, true, StudentLoan::SCOTLAND, StudentLoan::ON_OR_AFTER_1_SEPT_2012)).to eq StudentLoan::PLAN_4_AND_3
        end
      end

      context "with no student loan and with postgraduate masters and/or doctoral loan(s)" do
        it "returns PLAN_3" do
          expect(StudentLoan.determine_plan(false, true, nil, nil)).to eq StudentLoan::PLAN_3
        end
      end
    end
  end
end
