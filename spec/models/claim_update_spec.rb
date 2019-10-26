# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClaimUpdate do
  let(:claim_update) { ClaimUpdate.new(claim, params, context) }

  context "with parameters that are valid for the context" do
    let(:claim) { create(:claim, :submittable) }
    let(:context) { "bank-details" }
    let(:params) do
      {
        banking_name: "Jo Bloggs",
        bank_sort_code: "123456",
        bank_account_number: "12345678",
        building_society_roll_number: "1234/12345678",
        eligibility_attributes: {had_leadership_position: false},
      }
    end

    it "updates the claim and returns a truthy value" do
      expect(claim_update.perform).to be_truthy
      expect(claim.banking_name).to eq "Jo Bloggs"
      expect(claim.reload.bank_sort_code).to eq "123456"
      expect(claim.bank_account_number).to eq "12345678"
      expect(claim.building_society_roll_number).to eq "1234/12345678"
    end

    it "resets dependent attributes on the eligibility" do
      claim_update.perform
      expect(claim.eligibility.mostly_performed_leadership_duties).to be_nil
    end
  end

  context "with parameters missing for the context" do
    let(:claim) { create(:claim) }
    let(:context) { "bank-details" }
    let(:params) { {bank_sort_code: nil, bank_account_number: "12345678"} }

    it "doesn't update the claim and returns a falsy value" do
      expect(claim_update.perform).to be_falsy
      expect(claim.errors[:bank_sort_code]).to eq ["Enter a sort code"]
    end
  end

  describe "determining the student_loan_plan" do
    context "when the claimant has a plan" do
      let(:claim) { create(:claim, has_student_loan: true, student_loan_country: StudentLoans::ENGLAND) }
      let(:context) { "student-loan-start-date" }
      let(:params) { {student_loan_start_date: StudentLoans::ON_OR_AFTER_1_SEPT_2012} }

      it "determines the plan based on the answers" do
        expect(claim_update.perform).to be_truthy
        expect(claim.student_loan_plan).to eq StudentLoans::PLAN_2
      end
    end

    context "when the claimant does not have a plan" do
      let(:claim) { create(:claim) }
      let(:context) { "student-loan" }
      let(:params) { {has_student_loan: false} }

      it "sets the student_loan_plan to indicate it is not applicable" do
        expect(claim_update.perform).to be_truthy
        expect(claim.student_loan_plan).to eq Claim::NO_STUDENT_LOAN
      end
    end
  end

  describe "changing the answer to the student_loan_courses question" do
    let(:claim) do
      create(
        :claim,
        has_student_loan: true,
        student_loan_country: StudentLoans::ENGLAND,
        student_loan_courses: :one_course,
        student_loan_start_date: StudentLoans::ON_OR_AFTER_1_SEPT_2012,
        student_loan_plan: StudentLoans::PLAN_1
      )
    end

    let(:context) { "student-loan-courses" }
    let(:params) { {student_loan_courses: :two_or_more_courses} }

    it "resets the answer to the dependent student_loan_start_date answer and re-calculates the student loan plan" do
      expect(claim_update.perform).to be_truthy
      expect(claim.reload.student_loan_start_date).to be_nil
      expect(claim.student_loan_plan).to be_nil
    end
  end

  describe "changing the answer to the student_loan_country question" do
    let(:claim) do
      create(
        :claim,
        has_student_loan: true,
        student_loan_country: StudentLoans::ENGLAND,
        student_loan_courses: :one_course,
        student_loan_start_date: StudentLoans::ON_OR_AFTER_1_SEPT_2012,
        student_loan_plan: StudentLoans::PLAN_2
      )
    end

    let(:context) { "student-loan-country" }
    let(:params) { {student_loan_country: StudentLoans::SCOTLAND} }

    it "resets the answer to the subsequent student-loan-related answers and re-calculates the student loan plan" do
      expect(claim_update.perform).to be_truthy
      expect(claim.reload.student_loan_courses).to be_nil
      expect(claim.student_loan_start_date).to be_nil
      expect(claim.student_loan_plan).to eq StudentLoans::PLAN_1
    end
  end

  describe "changing the answer to the student_loan question" do
    let(:claim) do
      create(
        :claim,
        has_student_loan: true,
        student_loan_country: StudentLoans::ENGLAND,
        student_loan_courses: :one_course,
        student_loan_start_date: StudentLoans::ON_OR_AFTER_1_SEPT_2012,
        student_loan_plan: StudentLoans::PLAN_2
      )
    end

    let(:context) { "student-loan" }
    let(:params) { {has_student_loan: false} }

    it "resets the answer to the subsequent student-loan-related answers and re-calculates the student loan plan" do
      expect(claim_update.perform).to be_truthy
      expect(claim.reload.has_student_loan).to eq false
      expect(claim.student_loan_country).to be_nil
      expect(claim.student_loan_courses).to be_nil
      expect(claim.student_loan_start_date).to be_nil
      expect(claim.student_loan_plan).to eq Claim::NO_STUDENT_LOAN
    end
  end
end
