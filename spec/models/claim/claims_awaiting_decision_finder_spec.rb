require "rails_helper"

RSpec.describe Claim::ClaimsAwaitingDecisionFinder do
  let!(:fe_journey_configuration) { create(:journey_configuration, :further_education_payments, current_academic_year: fe_academic_year) }
  let!(:ap_journey_configuration) { create(:journey_configuration, :early_career_payments, current_academic_year: ecp_academic_year) }
  let!(:claim_fe_awaiting_decision_submitted_using_slc_data_false) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, academic_year: fe_academic_year, submitted_using_slc_data: false) }
  let!(:claim_fe_awaiting_decision_submitted_using_slc_data_nil) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, academic_year: fe_academic_year, submitted_using_slc_data: nil) }
  let!(:claim_fe_awaiting_decision_submitted_using_slc_data_true) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, academic_year: fe_academic_year, submitted_using_slc_data: true) }
  let!(:claim_fe_not_awaiting_decision) { create(:claim, :approved, policy: Policies::FurtherEducationPayments, academic_year: fe_academic_year, submitted_using_slc_data: false) }
  let!(:claim_fe_other_year) { create(:claim, :submitted, policy: Policies::FurtherEducationPayments, academic_year: fe_previous_academic_year, submitted_using_slc_data: false) }
  let!(:claim_ecp_awaiting_decision_submitted_using_slc_data_false) { create(:claim, :submitted, policy: Policies::EarlyCareerPayments, academic_year: ecp_academic_year, submitted_using_slc_data: false) }
  let!(:claim_ecp_awaiting_decision_submitted_using_slc_data_nil) { create(:claim, :submitted, policy: Policies::EarlyCareerPayments, academic_year: ecp_academic_year, submitted_using_slc_data: nil) }
  let!(:claim_ecp_awaiting_decision_submitted_using_slc_data_true) { create(:claim, :submitted, policy: Policies::EarlyCareerPayments, academic_year: ecp_academic_year, submitted_using_slc_data: true) }
  let!(:claim_ecp_not_awaiting_decision) { create(:claim, :approved, policy: Policies::EarlyCareerPayments, academic_year: ecp_academic_year, submitted_using_slc_data: false) }
  let!(:claim_ecp_other_year) { create(:claim, :submitted, policy: Policies::EarlyCareerPayments, academic_year: ecp_previous_academic_year, submitted_using_slc_data: false) }
  let!(:claim_sl_awaiting_decision_submitted_using_slc_data_false) { create(:claim, :submitted, policy: Policies::StudentLoans, academic_year: fe_academic_year, submitted_using_slc_data: false) }
  let(:fe_academic_year) { AcademicYear.new(2024) }
  let(:fe_previous_academic_year) { AcademicYear.new(2023) }
  let(:ecp_academic_year) { AcademicYear.new(2023) }
  let(:ecp_previous_academic_year) { AcademicYear.new(2022) }
  let(:policies) { [Policies::FurtherEducationPayments, Policies::EarlyCareerPayments] }

  describe "#claims_submitted_using_slc_data" do
    subject { described_class.new(policies: policies).claims_submitted_without_slc_data }

    it "returns claims for the correct academic year for each policy submitted without SLC data" do
      expect(subject).to contain_exactly(
        claim_fe_awaiting_decision_submitted_using_slc_data_false,
        claim_fe_awaiting_decision_submitted_using_slc_data_nil,
        claim_ecp_awaiting_decision_submitted_using_slc_data_false
      )
    end
  end
end
