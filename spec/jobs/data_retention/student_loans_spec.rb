require "rails_helper"

RSpec.describe DataRetention::PoliciesJob do
  before do
    FeatureFlag.enable!(:apply_data_retention_policy)
  end

  context "when the policy is student loans" do
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
        award_amount: 2000.0,
        claim_school_id: create(:school).id,
        current_school_id: create(:school).id,
        biology_taught: true,
        chemistry_taught: true,
        computing_taught: false,
        languages_taught: false,
        physics_taught: true,
        taught_eligible_subjects: true,
        had_leadership_position: false,
        mostly_performed_leadership_duties: false,
        claim_school_somewhere_else: true,
        teacher_reference_number: "1234567",
        qts_award_year: "on_or_after_cut_off_date",
        employment_status: "different_school"
      }
    end

    let(:claim) do
      create(
        :claim,
        **claim_attributes,
        policy: Policies::StudentLoans,
        academic_year: AcademicYear.new(2025),
        eligibility_attributes: eligibility_attributes,
        submitted_at: DateTime.new(2025, 9, 1, 0, 0, 0)
      )
    end

    context "when the claim is for the current academic year" do
      context "when the claim is inactive" do
        before do |example|
          travel_to(AcademicYear.new(2025).start_of_autumn_term + 20.weeks) do
            create(
              :decision,
              :rejected,
              claim: claim,
              created_at: DateTime.new(2025, 9, 1, 0, 0, 0)
            )

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
          travel_to(AcademicYear.new(2025).start_of_autumn_term + 20.weeks) do
            claim

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
      context "when the claim is inactive" do
        before do |example|
          travel_to(Time.utc(2031, 9, 1, 12, 0, 0)) do
            create(
              :decision,
              :rejected,
              claim: claim,
              created_at: DateTime.new(2025, 9, 1, 0, 0, 0)
            )

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

          # There's a callback that normalises trn casting it to a string,
          expect(eligibility.teacher_reference_number).to eq ""

          expect(eligibility.award_amount).to eq eligibility_attributes.fetch(:award_amount)
          expect(eligibility.claim_school_id).to eq eligibility_attributes.fetch(:claim_school_id)
          expect(eligibility.current_school_id).to eq eligibility_attributes.fetch(:current_school_id)
          expect(eligibility.biology_taught).to eq eligibility_attributes.fetch(:biology_taught)
          expect(eligibility.chemistry_taught).to eq eligibility_attributes.fetch(:chemistry_taught)
          expect(eligibility.computing_taught).to eq eligibility_attributes.fetch(:computing_taught)
          expect(eligibility.languages_taught).to eq eligibility_attributes.fetch(:languages_taught)
          expect(eligibility.physics_taught).to eq eligibility_attributes.fetch(:physics_taught)
          expect(eligibility.taught_eligible_subjects).to eq eligibility_attributes.fetch(:taught_eligible_subjects)
          expect(eligibility.had_leadership_position).to eq eligibility_attributes.fetch(:had_leadership_position)
          expect(eligibility.mostly_performed_leadership_duties).to eq eligibility_attributes.fetch(:mostly_performed_leadership_duties)
          expect(eligibility.claim_school_somewhere_else).to eq eligibility_attributes.fetch(:claim_school_somewhere_else)
          expect(eligibility.qts_award_year).to eq eligibility_attributes.fetch(:qts_award_year)
          expect(eligibility.employment_status).to eq eligibility_attributes.fetch(:employment_status)
        end
      end

      context "when the claim is active" do
        before do |example|
          travel_to(Time.utc(2026, 9, 1, 12, 0, 0)) do
            claim

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
  end
end
