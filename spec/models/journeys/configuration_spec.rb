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
    expect(described_class.new(routing_name: Journeys::TeacherStudentLoanReimbursement.routing_name, open_for_submissions: false)).not_to be_valid
    expect(described_class.new(routing_name: Journeys::TeacherStudentLoanReimbursement.routing_name, current_academic_year: "2020-2021", open_for_submissions: false)).not_to be_valid
    expect(described_class.new(routing_name: Journeys::TeacherStudentLoanReimbursement.routing_name, current_academic_year: "2020/2021", open_for_submissions: false)).to be_valid
  end

  describe "close datetime" do
    it "accepts close datetime when service is closed" do
      configuration = described_class.new(
        routing_name: Journeys::TeacherStudentLoanReimbursement.routing_name,
        current_academic_year: "2020/2021",
        open_for_submissions: false,
        close_at: Time.zone.parse("2026-08-01 14:30")
      )

      expect(configuration).to be_valid
      expect(configuration.save).to be true
      expect(configuration.close_at).to eq(Time.zone.parse("2026-08-01 14:30"))
    end

    it "requires close datetime to be in the future when the service is open" do
      configuration = described_class.new(
        routing_name: Journeys::TeacherStudentLoanReimbursement.routing_name,
        current_academic_year: "2020/2021",
        open_for_submissions: true,
        close_at: 1.hour.ago
      )

      expect(configuration).not_to be_valid
      expect(configuration.errors[:close_at]).to include("must be in the future")
    end

    it "accepts future close datetime when the service is open" do
      configuration = described_class.new(
        routing_name: Journeys::TeacherStudentLoanReimbursement.routing_name,
        current_academic_year: "2020/2021",
        open_for_submissions: true,
        close_at: 2.hours.from_now
      )

      expect(configuration).to be_valid
    end
  end
end
