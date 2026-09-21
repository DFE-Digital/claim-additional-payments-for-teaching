require "rails_helper"

RSpec.describe DataRetention::PoliciesJob do
  before do
    FeatureFlag.enable!(:apply_data_retention_policy)
  end

  context "when the policy is early years" do
    let(:claim_attributes) do
      {
        first_name: "Edna",
        middle_name: "Louise",
        surname: "Krabappel",
        email_address: "e.krabappel@springfield-elementary.edu",
        date_of_birth: Date.new(1949, 1, 21),
        address_line_1: "82 Evergreen Terrace",
        address_line_2: "Springfield",
        address_line_3: "Springfield County",
        address_line_4: "Springfield Region",
        postcode: "SP1 2NG",
        national_insurance_number: "QQ123456C",
        mobile_number: "07474000123",
        payroll_gender: "female",
        bank_sort_code: "220011",
        bank_account_number: "12345678",
        banking_name: "Edna Krabappel",
        reference: "SL123456",
        has_student_loan: true,
        student_loan_plan: "plan_2_and_3",
        provide_mobile_number: true,
        email_verified: true,
        mobile_verified: true,
        assigned_to_id: create(:dfe_signin_user).id,
        held: false,
        hmrc_bank_validation_succeeded: true,
        hmrc_bank_validation_responses: [{"code" => 200, "body" => "ok"}],
        qa_required: true,
        logged_in_with_tid: true,
        teacher_id_user_info: {"trn" => "1234567"},
        dqt_teacher_status: {"qts" => {"routes" => ["assessment_only"]}},
        submitted_using_slc_data: true,
        sent_one_time_password_at: DateTime.new(2025, 1, 1),
        decision_deadline: DateTime.new(2025, 2, 1)
      }
    end

    let(:eligibility_attributes) do
      {
        alternative_idv_claimant_bank_details_match: true,
        alternative_idv_claimant_date_of_birth: Date.new(1949, 1, 21),
        alternative_idv_claimant_email: "e.krabappel@springfield-elementary.edu",
        alternative_idv_claimant_employed_by_nursery: true,
        alternative_idv_claimant_employment_check_declaration: true,
        alternative_idv_claimant_national_insurance_number: "QQ123456",
        alternative_idv_claimant_postcode: "SP1 2NG",
        alternative_idv_completed_at: DateTime.new(2025, 1, 15),
        alternative_idv_reference: Reference.to_s,
        award_amount: 2000.0,
        child_facing_confirmation_given: true,
        nursery_urn: "123456",
        practitioner_claim_started_at: DateTime.new(2025, 1, 10),
        practitioner_first_name: "Edna",
        practitioner_reminder_email_last_sent_at: DateTime.new(2025, 1, 20),
        practitioner_reminder_email_sent_count: 1,
        practitioner_surname: "Krabappel",
        provider_claim_submitted_at: DateTime.new(2025, 1, 5),
        provider_email_address: "seymour.skinner@springfield-elementary.edu",
        provider_entered_contract_type: "permanent",
        provider_six_month_employment_reminder_sent_at: DateTime.new(2025, 1, 25),
        returner_contract_type: "permanent",
        returner_worked_with_children: true,
        returning_within_6_months: true,
        start_date: Date.new(2025, 2, 1)
      }
    end

    let(:claim) do
      create(
        :claim,
        **claim_attributes,
        policy: Policies::EarlyYearsPayments,
        academic_year: AcademicYear.new(2025),
        eligibility_attributes: eligibility_attributes,
        submitted_at: DateTime.new(2025, 9, 1, 0, 0, 0)
      )
    end

    context "when the claim is for the current academic year" do
      context "when the claim is inactive" do
        before do |example|
          create(:task, name: "employment", passed: true, claim: claim)

          create(
            :decision,
            :approved,
            claim: claim,
            created_at: DateTime.new(2025, 9, 1, 0, 0, 0)
          )

          create(
            :payment,
            claims: [claim],
            scheduled_payment_date: DateTime.new(2025, 9, 15, 0, 0, 0)
          )

          travel_to(AcademicYear.new(2025).start_of_autumn_term + 20.weeks) do
            perform_enqueued_jobs do
              described_class.perform_now
            end

            claim.reload
          end
        end

        it "doesn't scrub any attributes" do
          claim_attributes.each_key do |attribute|
            expect(claim.send(attribute)).to eq claim_attributes.fetch(attribute)
          end

          eligibility_attributes.each_key do |attribute|
            expect(claim.eligibility.send(attribute)).to eq eligibility_attributes.fetch(attribute)
          end
        end
      end

      context "when the claim is active" do
        before do |example|
          claim

          travel_to(AcademicYear.new(2025).start_of_autumn_term + 20.weeks) do
            perform_enqueued_jobs do
              described_class.perform_now
            end

            claim.reload
          end
        end

        it "doesn't scrub any attributes" do
          claim_attributes.each_key do |attribute|
            expect(claim.send(attribute)).to eq claim_attributes.fetch(attribute)
          end

          eligibility_attributes.each_key do |attribute|
            expect(claim.eligibility.send(attribute)).to eq eligibility_attributes.fetch(attribute)
          end
        end
      end
    end

    context "when the claim is from a prior academic year" do
      context "when the claim is active" do
        before do |example|
          claim

          travel_to(Time.utc(2026, 9, 1, 12, 0, 0)) do
            perform_enqueued_jobs do
              described_class.perform_now
            end

            claim.reload
          end
        end

        it "doesn't scrub any attributes" do
          claim_attributes.each_key do |attribute|
            expect(claim.send(attribute)).to eq claim_attributes.fetch(attribute)
          end

          eligibility_attributes.each_key do |attribute|
            expect(claim.eligibility.send(attribute)).to eq eligibility_attributes.fetch(attribute)
          end
        end
      end

      context "when the claim is inactive" do
        before do |example|
          create(:task, name: "employment", passed: true, claim: claim)

          create(
            :decision,
            :approved,
            claim: claim,
            created_at: DateTime.new(2025, 9, 1, 0, 0, 0)
          )

          create(
            :payment,
            :confirmed,
            claims: [claim],
            scheduled_payment_date: DateTime.new(2025, 9, 15, 0, 0, 0)
          )

          travel_to(Time.utc(2031, 9, 1, 12, 0, 0)) do
            perform_enqueued_jobs do
              described_class.perform_now
            end

            claim.reload
          end
        end

        it "scrubs the pii attributes" do
          expect(claim.first_name).to eq nil
          expect(claim.middle_name).to eq nil
          expect(claim.surname).to eq nil
          expect(claim.email_address).to eq nil
          expect(claim.date_of_birth).to eq nil
          expect(claim.address_line_1).to eq nil
          expect(claim.address_line_2).to eq nil
          expect(claim.address_line_3).to eq nil
          expect(claim.address_line_4).to eq nil
          expect(claim.postcode).to eq nil
          expect(claim.national_insurance_number).to eq nil
          expect(claim.mobile_number).to eq nil
          expect(claim.bank_sort_code).to eq nil
          expect(claim.bank_account_number).to eq nil
          expect(claim.banking_name).to eq nil
          expect(claim.teacher_id_user_info).to eq nil
          expect(claim.dqt_teacher_status).to eq nil
          expect(claim.hmrc_bank_validation_responses).to eq nil

          expect(claim.payroll_gender).to eq claim_attributes.fetch(:payroll_gender)
          expect(claim.hmrc_bank_validation_succeeded).to eq claim_attributes.fetch(:hmrc_bank_validation_succeeded)
          expect(claim.reference).to eq claim_attributes.fetch(:reference)
          expect(claim.has_student_loan).to eq claim_attributes.fetch(:has_student_loan)
          expect(claim.student_loan_plan).to eq claim_attributes.fetch(:student_loan_plan)
          expect(claim.provide_mobile_number).to eq claim_attributes.fetch(:provide_mobile_number)
          expect(claim.email_verified).to eq claim_attributes.fetch(:email_verified)
          expect(claim.mobile_verified).to eq claim_attributes.fetch(:mobile_verified)
          expect(claim.assigned_to_id).to eq claim_attributes.fetch(:assigned_to_id)
          expect(claim.held).to eq claim_attributes.fetch(:held)
          expect(claim.qa_required).to eq claim_attributes.fetch(:qa_required)
          expect(claim.logged_in_with_tid).to eq claim_attributes.fetch(:logged_in_with_tid)
          expect(claim.submitted_using_slc_data).to eq claim_attributes.fetch(:submitted_using_slc_data)
          expect(claim.sent_one_time_password_at).to eq claim_attributes.fetch(:sent_one_time_password_at)
          expect(claim.decision_deadline).to eq claim_attributes.fetch(:decision_deadline)

          eligibility = claim.eligibility
          expect(eligibility.alternative_idv_claimant_date_of_birth).to eq(nil)
          expect(eligibility.alternative_idv_claimant_email).to eq(nil)
          expect(eligibility.alternative_idv_claimant_national_insurance_number).to eq(nil)
          expect(eligibility.alternative_idv_claimant_postcode).to eq(nil)
          expect(eligibility.practitioner_first_name).to eq(nil)
          expect(eligibility.practitioner_surname).to eq(nil)
          expect(eligibility.provider_email_address).to eq(nil)

          expect(eligibility.alternative_idv_claimant_bank_details_match).to eq eligibility_attributes.fetch(:alternative_idv_claimant_bank_details_match)
          expect(eligibility.alternative_idv_claimant_employed_by_nursery).to eq eligibility_attributes.fetch(:alternative_idv_claimant_employed_by_nursery)
          expect(eligibility.alternative_idv_claimant_employment_check_declaration).to eq eligibility_attributes.fetch(:alternative_idv_claimant_employment_check_declaration)
          expect(eligibility.alternative_idv_completed_at).to eq eligibility_attributes.fetch(:alternative_idv_completed_at)
          expect(eligibility.alternative_idv_reference).to eq eligibility_attributes.fetch(:alternative_idv_reference)
          expect(eligibility.award_amount).to eq eligibility_attributes.fetch(:award_amount)
          expect(eligibility.child_facing_confirmation_given).to eq eligibility_attributes.fetch(:child_facing_confirmation_given)
          expect(eligibility.nursery_urn).to eq eligibility_attributes.fetch(:nursery_urn)
          expect(eligibility.practitioner_reminder_email_last_sent_at).to eq eligibility_attributes.fetch(:practitioner_reminder_email_last_sent_at)
          expect(eligibility.practitioner_reminder_email_sent_count).to eq eligibility_attributes.fetch(:practitioner_reminder_email_sent_count)
          expect(eligibility.practitioner_claim_started_at).to eq eligibility_attributes.fetch(:practitioner_claim_started_at)
          expect(eligibility.provider_claim_submitted_at).to eq eligibility_attributes.fetch(:provider_claim_submitted_at)
          expect(eligibility.provider_entered_contract_type).to eq eligibility_attributes.fetch(:provider_entered_contract_type)
          expect(eligibility.provider_six_month_employment_reminder_sent_at).to eq eligibility_attributes.fetch(:provider_six_month_employment_reminder_sent_at)
          expect(eligibility.returner_contract_type).to eq eligibility_attributes.fetch(:returner_contract_type)
          expect(eligibility.returner_worked_with_children).to eq eligibility_attributes.fetch(:returner_worked_with_children)
          expect(eligibility.returning_within_6_months).to eq eligibility_attributes.fetch(:returning_within_6_months)
          expect(eligibility.start_date).to eq eligibility_attributes.fetch(:start_date)
        end
      end
    end
  end
end
