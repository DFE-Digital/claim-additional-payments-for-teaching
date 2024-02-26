require "rails_helper"

RSpec.describe Claim, type: :model do
  before do
    academic_year = AcademicYear.new(2023)

    create(:policy_configuration, :maths_and_physics, current_academic_year: academic_year)
    create(:policy_configuration, :additional_payments, current_academic_year: academic_year)
    create(:policy_configuration, :student_loans, current_academic_year: academic_year)
  end

  describe ".destroy_all_for_policy" do
    let!(:maths_and_physics_claim) {
      create(
        :claim,
        :approved,
        :has_amendments,
        :has_all_passed_tasks,
        :has_notes,
        :has_support_ticket,
        policy: MathsAndPhysics
      )
    }

    let!(:student_loan_claim) {
      create(:claim,
        :approved,
        :has_amendments,
        :has_all_passed_tasks,
        :has_notes,
        :has_support_ticket,
        policy: StudentLoans)
    }

    let!(:ecp_claim) {
      create(
        :claim,
        :approved,
        :has_amendments,
        :has_all_passed_tasks,
        :has_notes,
        :has_support_ticket,
        policy: EarlyCareerPayments
      )
    }
    let!(:lupp_claim) {
      create(
        :claim,
        :approved,
        :has_amendments,
        :has_all_passed_tasks,
        :has_notes,
        :has_support_ticket,
        policy: LevellingUpPremiumPayments
      )
    }

    # TOPUP
    let(:lup_eligibility2) { create(:levelling_up_premium_payments_eligibility, :eligible, award_amount: 1500.0) }
    let!(:lupp_claim2) {
      create(
        :claim,
        :approved,
        :has_amendments,
        :has_all_passed_tasks,
        :has_notes,
        :has_support_ticket,
        policy: LevellingUpPremiumPayments,
        eligibility: lup_eligibility2
      )
    }
    let!(:lupp_claim_topup) {
      create(:topup, claim: lupp_claim2, award_amount: 500, created_by: create(:dfe_signin_user))
    }

    # TWO claims M&P and TSLR for the same TRN
    let!(:maths_and_physics_claim2) {
      create(
        :claim,
        :approved,
        :has_amendments,
        :has_all_passed_tasks,
        :has_notes,
        :has_support_ticket,
        policy: MathsAndPhysics
      )
    }

    let!(:student_loan_claim2) {
      create(:claim,
        :approved,
        :has_amendments,
        :has_all_passed_tasks,
        :has_notes,
        :has_support_ticket,
        policy: StudentLoans,
        # The following fields need to be the same for them to share the same payment
        teacher_reference_number: maths_and_physics_claim2.teacher_reference_number,
        date_of_birth: maths_and_physics_claim2.date_of_birth,
        national_insurance_number: maths_and_physics_claim2.national_insurance_number,
        bank_sort_code: maths_and_physics_claim2.bank_sort_code,
        bank_account_number: maths_and_physics_claim2.bank_account_number,
        building_society_roll_number: maths_and_physics_claim2.building_society_roll_number)
    }

    before do
      # Excludes lupp_claim2 because that is just the topup added to the payroll
      claims_for_payroll = [maths_and_physics_claim, student_loan_claim, lupp_claim, ecp_claim, maths_and_physics_claim2, student_loan_claim2]
      PayrollRun.create_with_claims!(claims_for_payroll, [lupp_claim_topup], created_by: create(:dfe_signin_user))

      # Make any other tables have some data to check there is no change with cascading deletes
      create(:file_upload)
      create(:reminder)
      create(:school_workforce_census)
      create(:student_loans_data)
      create(:teachers_pensions_service)
    end

    let(:old_payroll_run) do
      travel_to 2.months.ago do
        create(:payroll_run, :with_confirmations, claims_counts: {EarlyCareerPayments => 1, LevellingUpPremiumPayments => 1, StudentLoans => 1, MathsAndPhysics => 1})
      end
    end
    let(:maths_and_physics_claim3) { old_payroll_run.claims.by_policy(MathsAndPhysics).first }

    let(:maths_and_physics_claims) { [maths_and_physics_claim.reload, maths_and_physics_claim2.reload, maths_and_physics_claim3.reload] }
    let(:maths_and_physics_claims_count) { maths_and_physics_claims.count }
    let(:shared_payment_with_tslr) { student_loan_claim2.reload.payments.first }

    it "can only delete claims for MathsAndPhysics" do
      expect {
        Claim.destroy_all_for_policy(EarlyCareerPayments)
      }.to raise_error("Claims for policy #{EarlyCareerPayments} cannot be destroyed")

      expect {
        Claim.destroy_all_for_policy(LevellingUpPremiumPayments)
      }.to raise_error("Claims for policy #{LevellingUpPremiumPayments} cannot be destroyed")

      expect {
        Claim.destroy_all_for_policy(StudentLoans)
      }.to raise_error("Claims for policy #{StudentLoans} cannot be destroyed")
    end

    it "deletes all dependencies" do
      expect {
        Claim.destroy_all_for_policy(MathsAndPhysics)
      }.to change { Task.count }.by(-maths_and_physics_claims.sum { |c| c.tasks.size })
        # Models where data will be deleted
        .and change { Amendment.count }.by(-maths_and_physics_claims.sum { |c| c.amendments.size })
        .and change { Claim.by_policy(MathsAndPhysics).count }.by(-maths_and_physics_claims_count)
        .and change { Claim.count }.by(-maths_and_physics_claims_count)
        .and change { ClaimPayment.count }.by(-3) # Deletes the `maths_and_physics_claim`, `maths_and_physics_claim2` and `maths_and_physics_claim3` claim_payment join, so deletes 3
        .and change { Decision.count }.by(-maths_and_physics_claims.sum { |c| c.decisions.size })
        .and change { MathsAndPhysics::Eligibility.count }.by(-maths_and_physics_claims_count)
        .and change { Note.count }.by(-maths_and_physics_claims.sum { |c| c.notes.size })
        .and change { Payment.count }.by(-2) # This doesn't delete the shared payment for `maths_and_physics_claim2` and `student_loan_claim2`, so deletes 2
        .and change { PolicyConfiguration.count }.by(-1)
        .and change { shared_payment_with_tslr.claim_payments.size }.by(-1) # The shared payment loses the join with the deleted `maths_and_physics_claim2` claim, payment is retained for the TSLR claim
        .and change { SupportTicket.count }.by(-2) # maths_and_physics_claim3 doesn't have a support ticket, so deletes 2
        # Models where NO data should be deleted
        .and change { Claim.by_policy(EarlyCareerPayments).count }.by(0)
        .and change { Claim.by_policy(LevellingUpPremiumPayments).count }.by(0)
        .and change { Claim.by_policy(StudentLoans).count }.by(0)
        .and change { DfeSignIn::User.count }.by(0)
        .and change { EarlyCareerPayments::Eligibility.count }.by(0)
        .and change { FileUpload.count }.by(0)
        .and change { LevellingUpPremiumPayments::Eligibility.count }.by(0)
        .and change { LocalAuthority.count }.by(0)
        .and change { LocalAuthorityDistrict.count }.by(0)
        .and change { PaymentConfirmation.count }.by(0)
        .and change { PayrollRun.count }.by(0)
        .and change { Reminder.count }.by(0)
        .and change { School.count }.by(0)
        .and change { SchoolWorkforceCensus.count }.by(0)
        .and change { StudentLoans::Eligibility.count }.by(0)
        .and change { StudentLoansData.count }.by(0)
        .and change { TeachersPensionsService.count }.by(0)
        .and change { Topup.count }.by(0)
    end
  end
end
