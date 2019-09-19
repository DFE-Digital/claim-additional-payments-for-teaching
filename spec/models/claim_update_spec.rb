# frozen_string_literal: true

require "rails_helper"

RSpec.describe ClaimUpdate do
  let(:claim_update) { ClaimUpdate.new(claim, params, context) }

  context "with parameters that are valid for the context" do
    let(:claim) { create(:claim) }
    let(:context) { "bank-details" }
    let(:params) { {bank_sort_code: "123456", bank_account_number: "12345678"} }

    it "updates the claim and returns a truthy value" do
      expect(claim_update.perform).to be_truthy
      expect(claim.reload.bank_sort_code).to eq "123456"
      expect(claim.bank_account_number).to eq "12345678"
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

  context "when updating claim that is submittable in the “check-your-answers” context" do
    let(:claim) { create(:claim, :submittable) }
    let(:context) { "check-your-answers" }
    let(:params) { {} }

    it "transitions the claim to a submitted state and returns a truthy" do
      expect(claim_update.perform).to be_truthy
      expect(claim.reload).to be_submitted
    end

    it "queues a confirmation email to be sent to the claimant" do
      claim_update.perform
      expect(ActionMailer::DeliveryJob).to have_been_enqueued.with("ClaimMailer", "submitted", "deliver_now", claim)
    end
  end

  context "when updating an unsubmittable claim in the “check-your-answers” context" do
    let(:claim) { create(:claim, :submittable, first_name: nil) }
    let(:context) { "check-your-answers" }
    let(:params) { {} }

    it "returns false and does not queue a confirmation email" do
      expect(claim_update.perform).to be_falsy
      expect(ActionMailer::DeliveryJob).not_to have_been_enqueued
    end
  end

  describe "setting/resetting current_school based on the answer to employment_status" do
    context "when the update sets the employment_status to :claim_school" do
      let(:claim) do
        create(
          :claim,
          eligibility: build(
            :student_loans_eligibility,
            employments: [build(
              :student_loans_employment,
              school: schools(:penistone_grammar_school)
            )]
          )
        )
      end

      let(:context) { "still-teaching" }

      let(:params) do
        {
          eligibility_attributes: {
            employment_status: "claim_school",
          },
        }
      end

      it "automatically sets current_school to match the claim_school" do
        expect(claim_update.perform).to be_truthy
        expect(claim.eligibility.reload.employment_status).to eq "claim_school"
        expect(claim.eligibility.current_school).to eq schools(:penistone_grammar_school)
      end
    end

    context "when the update changes employment_status to :different_school" do
      let(:claim) do
        create(
          :claim,
          eligibility: build(
            :student_loans_eligibility,
            employment_status: :claim_school,
            current_school: schools(:penistone_grammar_school),
            employments: [build(
              :student_loans_employment,
              school: schools(:penistone_grammar_school)
            )]
          )
        )
      end

      let(:context) { "still-teaching" }

      let(:params) do
        {
          eligibility_attributes: {
            employment_status: "different_school",
          },
        }
      end

      it "resets the inferred current_school to nil" do
        expect(claim_update.perform).to be_truthy
        expect(claim.eligibility.reload.employment_status).to eq "different_school"
        expect(claim.eligibility.current_school).to be_nil
      end
    end

    context "when the update does not actually change the employment_status" do
      let(:claim) do
        create(
          :claim,
          eligibility: build(
            :student_loans_eligibility,
            employment_status: :different_school,
            current_school: schools(:hampstead_school),
            employments: [build(
              :student_loans_employment,
              school: schools(:penistone_grammar_school)
            )]
          )
        )
      end

      let(:context) { "still-teaching" }

      let(:params) do
        {
          eligibility_attributes: {
            employment_status: claim.eligibility.employment_status,
          },
        }
      end

      it "does not reset the current_school" do
        expect(claim_update.perform).to be_truthy
        expect(claim.eligibility.reload.employment_status).to eq "different_school"
        expect(claim.eligibility.current_school).to eq schools(:hampstead_school)
      end
    end
  end

  describe "setting/resetting employment_status when the claim_school changes" do
    let(:employment) do
      build(
        :student_loans_employment,
        school: schools(:penistone_grammar_school)
      )
    end

    let(:claim) do
      create(
        :claim,
        eligibility: build(
          :student_loans_eligibility,
          employment_status: :different_school,
          current_school: schools(:hampstead_school),
          employments: [employment]
        )
      )
    end

    let(:context) { "claim-school" }

    context "when the update changes the claim_school" do
      let(:params) do
        {
          eligibility_attributes: {
            employments_attributes: {
              "0" => {
                id: employment.id,
                school_id: schools(:hampstead_school).id,
              },
            },
          },
        }
      end

      it "resets the subsequent employment_status and current_school answers" do
        expect(claim_update.perform).to be_truthy
        expect(claim.eligibility.reload.employment_status).to be_nil
        expect(claim.eligibility.current_school).to be_nil
      end
    end

    context "when the update does not change the claim_school" do
      let(:params) do
        {
          eligibility_attributes: {
            employments_attributes: {
              "0" => {
                id: employment.id,
                school_id: claim.eligibility.selected_employment.school.id,
              },
            },
          },
        }
      end

      it "does not reset the subsequent employment_status and current_school answers" do
        expect(claim_update.perform).to be_truthy
        expect(claim.eligibility.reload.employment_status).to eq "different_school"
        expect(claim.eligibility.current_school).to eq schools(:hampstead_school)
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

  describe "changing the answer to the had_leadership_position question" do
    let(:eligibility) do
      create(
        :student_loans_eligibility,
        had_leadership_position: true,
        mostly_performed_leadership_duties: false
      )
    end

    let(:claim) do
      create(
        :claim,
        eligibility: eligibility
      )
    end

    let(:context) { "leadership-position" }

    let(:params) do
      {
        eligibility_attributes: {
          had_leadership_position: false,
        },
      }
    end

    it "resets the answer to the subsequent mostly_performed_leadership_duties question" do
      expect(claim_update.perform).to be_truthy

      expect(claim.reload.eligibility.had_leadership_position).to eq(false)
      expect(claim.eligibility.mostly_performed_leadership_duties).to be_nil
    end
  end
end
