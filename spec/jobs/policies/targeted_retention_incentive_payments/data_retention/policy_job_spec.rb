require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::DataRetention::PolicyJob do
  let!(:journey_configuration) do
    create(:journey_configuration, :targeted_retention_incentive_payments,
      current_academic_year: AcademicYear.new(2024))
  end

  let(:school) { create(:school, :targeted_retention_incentive_payments_eligible) }

  # Run the job on Nov 1, 2025 — in AY 2025/2026
  # AcademicYear.current = AcademicYear.new(2025)
  # start_of_academic_year = Sep 1, 2025
  #
  # "Old" = before Sep 1, 2025
  # "Current" = on or after Sep 1, 2025
  let(:job_run_date) { Date.new(2025, 11, 1) }

  def create_claim_with_all_attributes
    create(:claim, :submitted,
      policy: Policies::TargetedRetentionIncentivePayments,
      # --- Scrubbed attributes (19) ---
      first_name: "John",
      middle_name: "Michael",
      surname: "Smith",
      date_of_birth: Date.new(1990, 1, 1),
      address_line_1: "1 Test Road",
      address_line_2: "Test Town",
      address_line_3: "Test County",
      address_line_4: "Test Region",
      postcode: "AB1 2CD",
      payroll_gender: :female,
      national_insurance_number: "QQ123456C",
      bank_sort_code: "220011",
      bank_account_number: "12345678",
      building_society_roll_number: "1234567890",
      banking_name: "John Smith",
      hmrc_bank_validation_responses: [{code: 200, body: "ok"}],
      mobile_number: "07474000123",
      teacher_id_user_info: {"given_name" => "John"},
      dqt_teacher_status: {"trn" => "1234567"},
      # --- Retained attributes ---
      email_address: "test@example.com",
      email_verified: true,
      provide_mobile_number: true,
      mobile_verified: true,
      bank_or_building_society: :personal_bank_account,
      has_student_loan: true,
      student_loan_plan: StudentLoan::PLAN_1,
      details_check: true,
      hmrc_bank_validation_succeeded: true,
      held: false,
      qa_required: false,
      submitted_using_slc_data: false,
      # --- Eligibility ---
      eligibility_attributes: {
        teacher_reference_number: "1234567",
        award_amount: 2000.0,
        current_school_id: school.id,
        eligible_itt_subject: :mathematics,
        qualification: :postgraduate_itt,
        itt_academic_year: AcademicYear.new(2023),
        nqt_in_academic_year_after_itt: true,
        teaching_subject_now: true,
        employed_as_supply_teacher: false,
        subject_to_disciplinary_action: false,
        subject_to_formal_performance_action: false,
        eligible_degree_subject: true,
        employed_directly: true,
        has_entire_term_contract: true,
        induction_completed: true,
        school_somewhere_else: false
      })
  end

  def create_amendment_for(claim)
    create(:amendment, claim: claim, claim_changes: {
      "payroll_gender" => ["male", "female"],
      "date_of_birth" => [Date.new(1985, 6, 15), Date.new(1990, 1, 1)],
      "bank_sort_code" => ["111111", "220011"],
      "bank_account_number" => ["87654321", "12345678"],
      "student_loan_plan" => [StudentLoan::PLAN_2, StudentLoan::PLAN_1]
    })
  end

  def run_job_and_reload(claim)
    perform_enqueued_jobs do
      travel_to(job_run_date) { described_class.perform_now }
    end

    claim.reload
    claim.eligibility.reload
  end

  def assert_personal_data_scrubbed(claim)
    expect(claim.first_name).to be_nil
    expect(claim.middle_name).to be_nil
    expect(claim.surname).to be_nil
    expect(claim.date_of_birth).to be_nil
    expect(claim.address_line_1).to be_nil
    expect(claim.address_line_2).to be_nil
    expect(claim.address_line_3).to be_nil
    expect(claim.address_line_4).to be_nil
    expect(claim.postcode).to be_nil
    expect(claim.payroll_gender).to be_nil
    expect(claim.national_insurance_number).to be_nil
    expect(claim.bank_sort_code).to be_nil
    expect(claim.bank_account_number).to be_nil
    expect(claim.building_society_roll_number).to be_nil
    expect(claim.banking_name).to be_nil
    expect(claim.hmrc_bank_validation_responses).to be_nil
    expect(claim.mobile_number).to be_nil
    expect(claim.teacher_id_user_info).to be_nil
    expect(claim.dqt_teacher_status).to be_nil
  end

  def assert_personal_data_retained(claim)
    expect(claim.first_name).to eq("John")
    expect(claim.middle_name).to eq("Michael")
    expect(claim.surname).to eq("Smith")
    expect(claim.date_of_birth).to eq(Date.new(1990, 1, 1))
    expect(claim.address_line_1).to eq("1 Test Road")
    expect(claim.address_line_2).to eq("Test Town")
    expect(claim.address_line_3).to eq("Test County")
    expect(claim.address_line_4).to eq("Test Region")
    expect(claim.postcode).to eq("AB1 2CD")
    expect(claim.payroll_gender).to eq("female")
    expect(claim.national_insurance_number).to eq("QQ123456C")
    expect(claim.bank_sort_code).to eq("220011")
    expect(claim.bank_account_number).to eq("12345678")
    expect(claim.building_society_roll_number).to eq("1234567890")
    expect(claim.banking_name).to eq("John Smith")
    expect(claim.hmrc_bank_validation_responses).to eq([{"code" => 200, "body" => "ok"}])
    expect(claim.mobile_number).to eq("07474000123")
    expect(claim.teacher_id_user_info).to eq({"given_name" => "John"})
    expect(claim.dqt_teacher_status).to eq({"trn" => "1234567"})
  end

  def assert_non_personal_claim_attributes_retained(claim)
    expect(claim.email_address).to eq("test@example.com")
    expect(claim.email_verified).to eq(true)
    expect(claim.provide_mobile_number).to eq(true)
    expect(claim.mobile_verified).to eq(true)
    expect(claim.bank_or_building_society).to eq("personal_bank_account")
    expect(claim.has_student_loan).to eq(true)
    expect(claim.student_loan_plan).to eq(StudentLoan::PLAN_1)
    expect(claim.details_check).to eq(true)
    expect(claim.hmrc_bank_validation_succeeded).to eq(true)
    expect(claim.held).to eq(false)
    expect(claim.qa_required).to eq(false)
    expect(claim.submitted_using_slc_data).to eq(false)
    expect(claim.academic_year).to be_present
    expect(claim.reference).to be_present
    expect(claim.submitted_at).to be_present
    expect(claim.decision_deadline).to be_present
  end

  def assert_all_eligibility_attributes_retained(eligibility)
    expect(eligibility.teacher_reference_number).to eq("1234567")
    expect(eligibility.award_amount).to eq(2000.0)
    expect(eligibility.current_school_id).to eq(school.id)
    expect(eligibility.eligible_itt_subject).to eq("mathematics")
    expect(eligibility.qualification).to eq("postgraduate_itt")
    expect(eligibility.itt_academic_year).to eq(AcademicYear.new(2023))
    expect(eligibility.nqt_in_academic_year_after_itt).to eq(true)
    expect(eligibility.teaching_subject_now).to eq(true)
    expect(eligibility.employed_as_supply_teacher).to eq(false)
    expect(eligibility.subject_to_disciplinary_action).to eq(false)
    expect(eligibility.subject_to_formal_performance_action).to eq(false)
    expect(eligibility.eligible_degree_subject).to eq(true)
    expect(eligibility.employed_directly).to eq(true)
    expect(eligibility.has_entire_term_contract).to eq(true)
    expect(eligibility.induction_completed).to eq(true)
    expect(eligibility.school_somewhere_else).to eq(false)
  end

  def assert_amendment_personal_data_scrubbed(amendment)
    amendment.reload
    expect(amendment.claim_changes["payroll_gender"]).to be_nil
    expect(amendment.claim_changes["date_of_birth"]).to be_nil
    expect(amendment.claim_changes["bank_sort_code"]).to be_nil
    expect(amendment.claim_changes["bank_account_number"]).to be_nil
    expect(amendment.claim_changes["student_loan_plan"]).to eq([StudentLoan::PLAN_2, StudentLoan::PLAN_1])
    expect(amendment.personal_data_removed_at).to be_present
  end

  def assert_amendment_personal_data_retained(amendment)
    amendment.reload
    expect(amendment.claim_changes["payroll_gender"]).to eq(["male", "female"])
    expect(amendment.claim_changes["date_of_birth"]).to eq([Date.new(1985, 6, 15), Date.new(1990, 1, 1)])
    expect(amendment.claim_changes["bank_sort_code"]).to eq(["111111", "220011"])
    expect(amendment.claim_changes["bank_account_number"]).to eq(["87654321", "12345678"])
    expect(amendment.claim_changes["student_loan_plan"]).to eq([StudentLoan::PLAN_2, StudentLoan::PLAN_1])
    expect(amendment.personal_data_removed_at).to be_nil
  end

  context "old rejected claim (decision before start of current academic year)" do
    let!(:claim) do
      claim = create_claim_with_all_attributes
      create(:decision, :rejected, claim: claim, created_at: DateTime.new(2024, 10, 15))
      claim
    end

    before { run_job_and_reload(claim) }

    it "scrubs all 19 personal data attributes" do
      assert_personal_data_scrubbed(claim)
    end

    it "retains non-personal claim attributes" do
      assert_non_personal_claim_attributes_retained(claim)
    end

    it "retains all eligibility attributes" do
      assert_all_eligibility_attributes_retained(claim.eligibility)
    end
  end

  context "current rejected claim (decision after start of current academic year)" do
    let!(:claim) do
      claim = create_claim_with_all_attributes
      create(:decision, :rejected, claim: claim, created_at: DateTime.new(2025, 10, 15))
      claim
    end

    before { run_job_and_reload(claim) }

    it "does not scrub personal data attributes" do
      assert_personal_data_retained(claim)
    end

    it "retains non-personal claim attributes" do
      assert_non_personal_claim_attributes_retained(claim)
    end

    it "retains all eligibility attributes" do
      assert_all_eligibility_attributes_retained(claim.eligibility)
    end
  end

  context "old paid claim (payment scheduled before start of current academic year)" do
    let!(:claim) do
      claim = create_claim_with_all_attributes
      create(:decision, :approved, claim: claim)
      create(:payment, :confirmed, :with_figures, claims: [claim],
        scheduled_payment_date: Date.new(2024, 10, 15))
      claim
    end

    before { run_job_and_reload(claim) }

    it "scrubs all 19 personal data attributes" do
      assert_personal_data_scrubbed(claim)
    end

    it "retains non-personal claim attributes" do
      assert_non_personal_claim_attributes_retained(claim)
    end

    it "retains all eligibility attributes" do
      assert_all_eligibility_attributes_retained(claim.eligibility)
    end
  end

  context "current paid claim (payment scheduled after start of current academic year)" do
    let!(:claim) do
      claim = create_claim_with_all_attributes
      create(:decision, :approved, claim: claim)
      create(:payment, :confirmed, :with_figures, claims: [claim],
        scheduled_payment_date: Date.new(2025, 10, 15))
      claim
    end

    before { run_job_and_reload(claim) }

    it "does not scrub personal data attributes" do
      assert_personal_data_retained(claim)
    end

    it "retains non-personal claim attributes" do
      assert_non_personal_claim_attributes_retained(claim)
    end

    it "retains all eligibility attributes" do
      assert_all_eligibility_attributes_retained(claim.eligibility)
    end
  end

  context "undecided claim (no decision or payment)" do
    let!(:claim) { create_claim_with_all_attributes }

    before { run_job_and_reload(claim) }

    it "does not scrub personal data attributes" do
      assert_personal_data_retained(claim)
    end

    it "retains non-personal claim attributes" do
      assert_non_personal_claim_attributes_retained(claim)
    end

    it "retains all eligibility attributes" do
      assert_all_eligibility_attributes_retained(claim.eligibility)
    end
  end

  context "amendment scrubbing" do
    context "old rejected claim (decision before start of current academic year)" do
      let!(:claim) do
        claim = create_claim_with_all_attributes
        create(:decision, :rejected, claim: claim, created_at: DateTime.new(2024, 10, 15))
        claim
      end
      let!(:amendment) { create_amendment_for(claim) }

      before { run_job_and_reload(claim) }

      it "scrubs amendment personal data" do
        assert_amendment_personal_data_scrubbed(amendment)
      end
    end

    context "current rejected claim (decision after start of current academic year)" do
      let!(:claim) do
        claim = create_claim_with_all_attributes
        create(:decision, :rejected, claim: claim, created_at: DateTime.new(2025, 10, 15))
        claim
      end
      let!(:amendment) { create_amendment_for(claim) }

      before { run_job_and_reload(claim) }

      it "retains amendment personal data" do
        assert_amendment_personal_data_retained(amendment)
      end
    end

    context "old paid claim (payment scheduled before start of current academic year)" do
      let!(:claim) do
        claim = create_claim_with_all_attributes
        create(:decision, :approved, claim: claim)
        claim
      end
      let!(:amendment) { create_amendment_for(claim) }
      let!(:payment) do
        create(:payment, :confirmed, :with_figures, claims: [claim],
          scheduled_payment_date: Date.new(2024, 10, 15))
      end

      before { run_job_and_reload(claim) }

      it "scrubs amendment personal data" do
        assert_amendment_personal_data_scrubbed(amendment)
      end
    end

    context "current paid claim (payment scheduled after start of current academic year)" do
      let!(:claim) do
        claim = create_claim_with_all_attributes
        create(:decision, :approved, claim: claim)
        claim
      end
      let!(:amendment) { create_amendment_for(claim) }
      let!(:payment) do
        create(:payment, :confirmed, :with_figures, claims: [claim],
          scheduled_payment_date: Date.new(2025, 10, 15))
      end

      before { run_job_and_reload(claim) }

      it "retains amendment personal data" do
        assert_amendment_personal_data_retained(amendment)
      end
    end

    context "undecided claim (no decision or payment)" do
      let!(:claim) { create_claim_with_all_attributes }
      let!(:amendment) { create_amendment_for(claim) }

      before { run_job_and_reload(claim) }

      it "retains amendment personal data" do
        assert_amendment_personal_data_retained(amendment)
      end
    end
  end
end
