# frozen_string_literal: true

require "rails_helper"

RSpec.describe Journeys::Configuration do
  context "with journey configuration records" do
    let!(:student_loans) { create(:journey_configuration, :student_loans) }
    let!(:targeted_retention_incentive_payments) { create(:journey_configuration, :targeted_retention_incentive_payments) }

    describe "#targeted_retention_incentive_payments?" do
      it "returns true" do
        expect(targeted_retention_incentive_payments.targeted_retention_incentive_payments?).to be true
      end

      it "returns false" do
        expect(student_loans.targeted_retention_incentive_payments?).to be false
      end
    end

    describe "#journey" do
      it "returns the corresponding Journey" do
        expect(targeted_retention_incentive_payments.journey).to eq(Journeys::TargetedRetentionIncentivePayments)
        expect(student_loans.journey).to eq(Journeys::TeacherStudentLoanReimbursement)
      end
    end
  end

  it "validates academic years are formated like '2020/2021'" do
    expect(described_class.new(routing_name: Journeys::TeacherStudentLoanReimbursement.routing_name)).not_to be_valid
    expect(described_class.new(routing_name: Journeys::TeacherStudentLoanReimbursement.routing_name, current_academic_year: "2020-2021")).not_to be_valid
    expect(described_class.new(routing_name: Journeys::TeacherStudentLoanReimbursement.routing_name, current_academic_year: "2020/2021")).to be_valid
  end
end
