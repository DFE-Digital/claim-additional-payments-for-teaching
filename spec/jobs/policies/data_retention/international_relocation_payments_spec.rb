require "rails_helper"

RSpec.describe Policies::DataRetention::PoliciesJob do
  before do
    FeatureFlag.enable!(:apply_data_retention_policy)
  end

  context "when the policy is international relocation payments" do
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
        application_route: "teacher",
        award_amount: 2000.0,
        breaks_in_employment: true,
        changed_workplace_or_new_contract: true,
        current_school_id: create(:school).id,
        date_of_entry: Date.new(2025, 1, 1),
        employment_history: [
          Policies::InternationalRelocationPayments::EmploymentHistory::Employment.new(
            id: "abc123",
            created_by_id: create(:dfe_signin_user).id,
            school_id: create(:school).id,
            employment_contract_of_at_least_one_year: true,
            employment_end_date: Date.new(2025, 1, 31),
            employment_start_date: Date.new(2024, 1, 1),
            met_minimum_teaching_hours: true,
            subject_employed_to_teach: "mathematics"
          )
        ],
        nationality: "British",
        one_year: true,
        passport_number: "123456789",
        previous_year_claim_ids: [create(:claim, :approved).id],
        school_headteacher_name: "Seymour Skinner",
        start_date: Date.new(2025, 2, 1),
        state_funded_secondary_school: true,
        subject: "mathematics",
        visa_type: "British national overseas"
      }
    end

    let(:claim) do
      create(
        :claim,
        **claim_attributes,
        policy: Policies::InternationalRelocationPayments,
        academic_year: AcademicYear.new(2025),
        eligibility_attributes: eligibility_attributes,
        submitted_at: DateTime.new(2025, 9, 1, 0, 0, 0)
      )
    end

    context "when the claim is for the current academic year" do
      context "when the claim is inactive" do
        before do |example|
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

          travel_to(Time.utc(2026, 9, 1, 12, 0, 0)) do
            perform_enqueued_jobs do
              described_class.perform_now
            end

            claim.reload
          end
        end

        it "scrubs some pii attributes" do
          expect(claim.email_address).to eq nil
          expect(claim.mobile_number).to eq nil
          expect(claim.teacher_id_user_info).to eq nil

          expect(claim.first_name).to eq claim_attributes.fetch(:first_name)
          expect(claim.middle_name).to eq claim_attributes.fetch(:middle_name)
          expect(claim.surname).to eq claim_attributes.fetch(:surname)
          expect(claim.date_of_birth).to eq claim_attributes.fetch(:date_of_birth)
          expect(claim.address_line_1).to eq claim_attributes.fetch(:address_line_1)
          expect(claim.address_line_2).to eq claim_attributes.fetch(:address_line_2)
          expect(claim.address_line_3).to eq claim_attributes.fetch(:address_line_3)
          expect(claim.address_line_4).to eq claim_attributes.fetch(:address_line_4)
          expect(claim.postcode).to eq claim_attributes.fetch(:postcode)
          expect(claim.national_insurance_number).to eq claim_attributes.fetch(:national_insurance_number)
          expect(claim.bank_sort_code).to eq claim_attributes.fetch(:bank_sort_code)
          expect(claim.bank_account_number).to eq claim_attributes.fetch(:bank_account_number)
          expect(claim.banking_name).to eq claim_attributes.fetch(:banking_name)
          expect(claim.dqt_teacher_status).to eq claim_attributes.fetch(:dqt_teacher_status)
          expect(claim.hmrc_bank_validation_responses).to eq claim_attributes.fetch(:hmrc_bank_validation_responses)

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

          expect(eligibility.passport_number).to eq eligibility_attributes.fetch(:passport_number)
          expect(eligibility.school_headteacher_name).to eq eligibility_attributes.fetch(:school_headteacher_name)

          expect(eligibility.application_route).to eq eligibility_attributes.fetch(:application_route)
          expect(eligibility.award_amount).to eq eligibility_attributes.fetch(:award_amount)
          expect(eligibility.breaks_in_employment).to eq eligibility_attributes.fetch(:breaks_in_employment)
          expect(eligibility.changed_workplace_or_new_contract).to eq eligibility_attributes.fetch(:changed_workplace_or_new_contract)
          expect(eligibility.current_school_id).to eq eligibility_attributes.fetch(:current_school_id)
          expect(eligibility.date_of_entry).to eq eligibility_attributes.fetch(:date_of_entry)
          expect(eligibility.employment_history).to eq eligibility_attributes.fetch(:employment_history)
          expect(eligibility.nationality).to eq eligibility_attributes.fetch(:nationality)
          expect(eligibility.one_year).to eq eligibility_attributes.fetch(:one_year)
          expect(eligibility.previous_year_claim_ids).to eq eligibility_attributes.fetch(:previous_year_claim_ids)
          expect(eligibility.start_date).to eq eligibility_attributes.fetch(:start_date)
          expect(eligibility.state_funded_secondary_school).to eq eligibility_attributes.fetch(:state_funded_secondary_school)
          expect(eligibility.subject).to eq eligibility_attributes.fetch(:subject)
          expect(eligibility.visa_type).to eq eligibility_attributes.fetch(:visa_type)
        end
      end
    end

    context "when the claim is two academic years old" do
      context "when the claim is inactive" do
        before do |example|
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

          travel_to(Time.utc(2027, 9, 1, 12, 0, 0)) do
            perform_enqueued_jobs do
              described_class.perform_now
            end

            claim.reload
          end
        end

        it "scrubs some pii attributes" do
          expect(claim.email_address).to eq nil
          expect(claim.mobile_number).to eq nil
          expect(claim.teacher_id_user_info).to eq nil

          expect(claim.first_name).to eq claim_attributes.fetch(:first_name)
          expect(claim.middle_name).to eq claim_attributes.fetch(:middle_name)
          expect(claim.surname).to eq claim_attributes.fetch(:surname)
          expect(claim.date_of_birth).to eq claim_attributes.fetch(:date_of_birth)
          expect(claim.address_line_1).to eq claim_attributes.fetch(:address_line_1)
          expect(claim.address_line_2).to eq claim_attributes.fetch(:address_line_2)
          expect(claim.address_line_3).to eq claim_attributes.fetch(:address_line_3)
          expect(claim.address_line_4).to eq claim_attributes.fetch(:address_line_4)
          expect(claim.postcode).to eq claim_attributes.fetch(:postcode)
          expect(claim.national_insurance_number).to eq claim_attributes.fetch(:national_insurance_number)
          expect(claim.bank_sort_code).to eq claim_attributes.fetch(:bank_sort_code)
          expect(claim.bank_account_number).to eq claim_attributes.fetch(:bank_account_number)
          expect(claim.banking_name).to eq claim_attributes.fetch(:banking_name)
          expect(claim.dqt_teacher_status).to eq claim_attributes.fetch(:dqt_teacher_status)
          expect(claim.hmrc_bank_validation_responses).to eq claim_attributes.fetch(:hmrc_bank_validation_responses)

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

          expect(eligibility.passport_number).to eq nil
          expect(eligibility.school_headteacher_name).to eq nil

          expect(eligibility.application_route).to eq eligibility_attributes.fetch(:application_route)
          expect(eligibility.award_amount).to eq eligibility_attributes.fetch(:award_amount)
          expect(eligibility.breaks_in_employment).to eq eligibility_attributes.fetch(:breaks_in_employment)
          expect(eligibility.changed_workplace_or_new_contract).to eq eligibility_attributes.fetch(:changed_workplace_or_new_contract)
          expect(eligibility.current_school_id).to eq eligibility_attributes.fetch(:current_school_id)
          expect(eligibility.date_of_entry).to eq eligibility_attributes.fetch(:date_of_entry)
          expect(eligibility.employment_history).to eq eligibility_attributes.fetch(:employment_history)
          expect(eligibility.nationality).to eq eligibility_attributes.fetch(:nationality)
          expect(eligibility.one_year).to eq eligibility_attributes.fetch(:one_year)
          expect(eligibility.previous_year_claim_ids).to eq eligibility_attributes.fetch(:previous_year_claim_ids)
          expect(eligibility.start_date).to eq eligibility_attributes.fetch(:start_date)
          expect(eligibility.state_funded_secondary_school).to eq eligibility_attributes.fetch(:state_funded_secondary_school)
          expect(eligibility.subject).to eq eligibility_attributes.fetch(:subject)
          expect(eligibility.visa_type).to eq eligibility_attributes.fetch(:visa_type)
        end
      end
    end
  end
end
