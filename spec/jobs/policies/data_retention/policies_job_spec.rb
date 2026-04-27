require "rails_helper"

RSpec.describe Policies::DataRetention::PoliciesJob do
  context "When the policy is TargetedRetentionIncentivePayments" do
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
      expect(claim.email_address).to be_nil
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
      expect(claim.email_address).to eq("test@example.com")
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

  context "when the policy is FurtherEducationPayments" do
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
        hmrc_bank_validation_responses: [{"code" => 200, "body" => "ok"}],
        payroll_gender: "female",
        onelogin_credentials: {"uid" => "12345"},
        onelogin_idv_date_of_birth: Date.new(1949, 1, 21),
        onelogin_idv_first_name: "Edna",
        onelogin_idv_full_name: "Edna Louise Krabappel",
        onelogin_idv_last_name: "Krabappel",
        onelogin_idv_return_codes: ["A"],
        onelogin_uid: "12345",
        onelogin_user_info: {"given_name" => "Edna"},
        bank_sort_code: "220011",
        bank_account_number: "12345678",
        banking_name: "Edna Krabappel"
      }
    end

    let(:eligibility_attributes) do
      {
        award_amount: 2000.0,
        building_construction_courses: ["carpentry"],
        chemistry_courses: ["general"],
        claimant_date_of_birth: Date.new(1949, 1, 21),
        claimant_identity_verified_at: DateTime.new(2025, 1, 1),
        claimant_national_insurance_number: "QQ123456C",
        claimant_passport_number: "123456789",
        claimant_postcode: "SP1 2NG",
        claimant_valid_passport: true,
        computing_courses: ["general"],
        contract_type: "permanent",
        early_years_courses: ["general"],
        engineering_manufacturing_courses: ["general"],
        fixed_term_full_year: false,
        flagged_as_duplicate: false,
        flagged_as_mismatch_on_teaching_start_year: false,
        flagged_as_previously_start_year_matches_claim_false: false,
        further_education_teaching_start_year: "2020",
        half_teaching_hours: false,
        hours_teaching_eligible_subjects: true,
        maths_courses: ["general"],
        passport_number: "123456789",
        physics_courses: ["general"],
        possible_school_id: create(:school).id,
        provider_assigned_to_id: create(:dfe_signin_user).id,
        provider_verification_chase_email_last_sent_at: DateTime.new(2025, 1, 1),
        provider_verification_claimant_bank_details_match: true,
        provider_verification_claimant_date_of_birth: Date.new(1949, 1, 21),
        provider_verification_claimant_email: "e.krabappel@springfield-elementary.edu",
        provider_verification_claimant_employed_by_college: true,
        provider_verification_claimant_employment_check_declaration: true,
        provider_verification_claimant_national_insurance_number: "QQ123456C",
        provider_verification_claimant_postcode: "SP1 2NG",
        provider_verification_completed_at: DateTime.new(2025, 1, 1),
        provider_verification_continued_employment: true,
        provider_verification_contract_covers_full_academic_year: true,
        provider_verification_contract_type: "permanent",
        provider_verification_deadline: DateTime.new(2025, 2, 1),
        provider_verification_declaration: true,
        provider_verification_disciplinary_action: false,
        provider_verification_email_count: 2,
        provider_verification_email_last_sent_at: DateTime.new(2025, 1, 1),
        provider_verification_half_teaching_hours: false,
        provider_verification_half_timetabled_teaching_time: false,
        provider_verification_not_started_qualification_reason_other: nil,
        provider_verification_not_started_qualification_reasons: [],
        provider_verification_performance_measures: false,
        provider_verification_started_at: DateTime.new(2025, 1, 1),
        provider_verification_taught_at_least_one_academic_term: true,
        provider_verification_teaching_hours_per_week: "12_to_20_hours_per_week",
        provider_verification_teaching_qualification: "postgraduate_itt",
        provider_verification_teaching_responsibilities: true,
        provider_verification_teaching_start_year: "2020",
        provider_verification_verified_by_id: create(:dfe_signin_user).id,
        provision_search: "springfield",
        school_id: create(:school).id,
        subject_to_disciplinary_action: false,
        subject_to_formal_performance_action: false,
        subjects_taught: ["carpentry"],
        taught_at_least_one_term: true,
        teacher_reference_number: "1234567",
        teaching_hours_per_week: "12_to_20_hours_per_week",
        teaching_qualification: "postgraduate_itt",
        teaching_responsibilities: true,
        valid_passport: true,
        verification: {"some" => "json"},
        work_email: "e.krabappel@springfield-elementary.edu",
        work_email_verified: true
      }
    end

    let(:claim) do
      create(
        :claim,
        **claim_attributes,
        policy: Policies::FurtherEducationPayments,
        academic_year: AcademicYear.new(2025),
        eligibility_attributes: eligibility_attributes,
        submitted_at: DateTime.new(2025, 9, 1, 0, 0, 0)
      ).tap do |claim|
        create(
          :decision,
          :rejected,
          claim: claim,
          created_at: DateTime.new(2025, 9, 1, 0, 0, 0)
        )
      end
    end

    context "when the claim is more than 5 academic years old" do
      around do |example|
        travel_to(AcademicYear.new(2030).start_of_autumn_term.beginning_of_day) do
          claim

          perform_enqueued_jobs do
            described_class.perform_now
          end

          claim.reload

          example.run
        end
      end

      it "scrubs all pii attributes" do
        expect(claim.first_name).to be nil
        expect(claim.middle_name).to be nil
        expect(claim.surname).to be nil
        expect(claim.date_of_birth).to be nil
        expect(claim.address_line_1).to be nil
        expect(claim.address_line_2).to be nil
        expect(claim.address_line_3).to be nil
        expect(claim.address_line_4).to be nil
        expect(claim.postcode).to be nil
        expect(claim.national_insurance_number).to be nil
        expect(claim.mobile_number).to be nil
        expect(claim.hmrc_bank_validation_responses).to be nil
        expect(claim.payroll_gender).to be nil
        expect(claim.onelogin_credentials).to be nil
        expect(claim.onelogin_idv_date_of_birth).to be nil
        expect(claim.onelogin_idv_first_name).to be nil
        expect(claim.onelogin_idv_full_name).to be nil
        expect(claim.onelogin_idv_last_name).to be nil
        expect(claim.onelogin_idv_return_codes).to be nil
        expect(claim.onelogin_uid).to be nil
        expect(claim.onelogin_user_info).to be nil
        expect(claim.email_address).to be nil
        expect(claim.bank_sort_code).to be nil
        expect(claim.bank_account_number).to be nil
        expect(claim.banking_name).to be nil

        eligibility = claim.eligibility

        expect(eligibility.claimant_date_of_birth).to be nil
        expect(eligibility.claimant_national_insurance_number).to be nil
        expect(eligibility.claimant_passport_number).to be nil
        expect(eligibility.claimant_postcode).to be nil
        expect(eligibility.passport_number).to be nil
        expect(eligibility.provider_verification_claimant_date_of_birth).to be nil
        expect(eligibility.provider_verification_claimant_email).to be nil
        expect(eligibility.provider_verification_claimant_national_insurance_number).to be nil
        expect(eligibility.provider_verification_claimant_postcode).to be nil
        expect(eligibility.teacher_reference_number).to be nil
        expect(eligibility.verification).to be nil
        expect(eligibility.work_email).to be nil
        expect(eligibility.provider_assigned_to_id).to eq nil
        expect(eligibility.provider_verification_verified_by_id).to eq nil

        expect(eligibility.award_amount).to eq eligibility_attributes.fetch(:award_amount)
        expect(eligibility.building_construction_courses).to eq eligibility_attributes.fetch(:building_construction_courses)
        expect(eligibility.chemistry_courses).to eq eligibility_attributes.fetch(:chemistry_courses)
        expect(eligibility.claimant_identity_verified_at).to eq eligibility_attributes.fetch(:claimant_identity_verified_at)
        expect(eligibility.claimant_valid_passport).to eq eligibility_attributes.fetch(:claimant_valid_passport)
        expect(eligibility.computing_courses).to eq eligibility_attributes.fetch(:computing_courses)
        expect(eligibility.contract_type).to eq eligibility_attributes.fetch(:contract_type)
        expect(eligibility.early_years_courses).to eq eligibility_attributes.fetch(:early_years_courses)
        expect(eligibility.engineering_manufacturing_courses).to eq eligibility_attributes.fetch(:engineering_manufacturing_courses)
        expect(eligibility.fixed_term_full_year).to eq eligibility_attributes.fetch(:fixed_term_full_year)
        expect(eligibility.flagged_as_duplicate).to eq eligibility_attributes.fetch(:flagged_as_duplicate)
        expect(eligibility.flagged_as_mismatch_on_teaching_start_year).to eq eligibility_attributes.fetch(:flagged_as_mismatch_on_teaching_start_year)
        expect(eligibility.flagged_as_previously_start_year_matches_claim_false).to eq eligibility_attributes.fetch(:flagged_as_previously_start_year_matches_claim_false)
        expect(eligibility.further_education_teaching_start_year).to eq eligibility_attributes.fetch(:further_education_teaching_start_year)
        expect(eligibility.half_teaching_hours).to eq eligibility_attributes.fetch(:half_teaching_hours)
        expect(eligibility.hours_teaching_eligible_subjects).to eq eligibility_attributes.fetch(:hours_teaching_eligible_subjects)
        expect(eligibility.maths_courses).to eq eligibility_attributes.fetch(:maths_courses)
        expect(eligibility.physics_courses).to eq eligibility_attributes.fetch(:physics_courses)
        expect(eligibility.possible_school_id).to eq eligibility_attributes.fetch(:possible_school_id)
        expect(eligibility.provider_verification_chase_email_last_sent_at).to eq eligibility_attributes.fetch(:provider_verification_chase_email_last_sent_at)
        expect(eligibility.provider_verification_claimant_bank_details_match).to eq eligibility_attributes.fetch(:provider_verification_claimant_bank_details_match)
        expect(eligibility.provider_verification_claimant_employed_by_college).to eq eligibility_attributes.fetch(:provider_verification_claimant_employed_by_college)
        expect(eligibility.provider_verification_claimant_employment_check_declaration).to eq eligibility_attributes.fetch(:provider_verification_claimant_employment_check_declaration)
        expect(eligibility.provider_verification_completed_at).to eq eligibility_attributes.fetch(:provider_verification_completed_at)
        expect(eligibility.provider_verification_continued_employment).to eq eligibility_attributes.fetch(:provider_verification_continued_employment)
        expect(eligibility.provider_verification_contract_covers_full_academic_year).to eq eligibility_attributes.fetch(:provider_verification_contract_covers_full_academic_year)
        expect(eligibility.provider_verification_contract_type).to eq eligibility_attributes.fetch(:provider_verification_contract_type)
        expect(eligibility.provider_verification_deadline).to eq eligibility_attributes.fetch(:provider_verification_deadline)
        expect(eligibility.provider_verification_declaration).to eq eligibility_attributes.fetch(:provider_verification_declaration)
        expect(eligibility.provider_verification_disciplinary_action).to eq eligibility_attributes.fetch(:provider_verification_disciplinary_action)
        expect(eligibility.provider_verification_email_count).to eq eligibility_attributes.fetch(:provider_verification_email_count)
        expect(eligibility.provider_verification_email_last_sent_at).to eq eligibility_attributes.fetch(:provider_verification_email_last_sent_at)
        expect(eligibility.provider_verification_half_teaching_hours).to eq eligibility_attributes.fetch(:provider_verification_half_teaching_hours)
        expect(eligibility.provider_verification_half_timetabled_teaching_time).to eq eligibility_attributes.fetch(:provider_verification_half_timetabled_teaching_time)
        expect(eligibility.provider_verification_not_started_qualification_reason_other).to eq eligibility_attributes.fetch(:provider_verification_not_started_qualification_reason_other)
        expect(eligibility.provider_verification_not_started_qualification_reasons).to eq eligibility_attributes.fetch(:provider_verification_not_started_qualification_reasons)
        expect(eligibility.provider_verification_performance_measures).to eq eligibility_attributes.fetch(:provider_verification_performance_measures)
        expect(eligibility.provider_verification_started_at).to eq eligibility_attributes.fetch(:provider_verification_started_at)
        expect(eligibility.provider_verification_taught_at_least_one_academic_term).to eq eligibility_attributes.fetch(:provider_verification_taught_at_least_one_academic_term)
        expect(eligibility.provider_verification_teaching_hours_per_week).to eq eligibility_attributes.fetch(:provider_verification_teaching_hours_per_week)
        expect(eligibility.provider_verification_teaching_qualification).to eq eligibility_attributes.fetch(:provider_verification_teaching_qualification)
        expect(eligibility.provider_verification_teaching_responsibilities).to eq eligibility_attributes.fetch(:provider_verification_teaching_responsibilities)
        expect(eligibility.provider_verification_teaching_start_year).to eq eligibility_attributes.fetch(:provider_verification_teaching_start_year)
        expect(eligibility.provision_search).to eq eligibility_attributes.fetch(:provision_search)
        expect(eligibility.school_id).to eq eligibility_attributes.fetch(:school_id)
        expect(eligibility.subject_to_disciplinary_action).to eq eligibility_attributes.fetch(:subject_to_disciplinary_action)
        expect(eligibility.subject_to_formal_performance_action).to eq eligibility_attributes.fetch(:subject_to_formal_performance_action)
        expect(eligibility.subjects_taught).to eq eligibility_attributes.fetch(:subjects_taught)
        expect(eligibility.taught_at_least_one_term).to eq eligibility_attributes.fetch(:taught_at_least_one_term)
        expect(eligibility.teaching_hours_per_week).to eq eligibility_attributes.fetch(:teaching_hours_per_week)
        expect(eligibility.teaching_qualification).to eq eligibility_attributes.fetch(:teaching_qualification)
        expect(eligibility.teaching_responsibilities).to eq eligibility_attributes.fetch(:teaching_responsibilities)
        expect(eligibility.valid_passport).to eq eligibility_attributes.fetch(:valid_passport)
        expect(eligibility.work_email_verified).to eq eligibility_attributes.fetch(:work_email_verified)
      end
    end

    context "when the claim is not more than 5 academic years old" do
      context "when the claim is an inactive claim in the prior academic term" do
        around do |example|
          travel_to(AcademicYear.new(2026).start_of_autumn_term.beginning_of_day) do
            claim

            perform_enqueued_jobs do
              described_class.perform_now
            end

            claim.reload

            example.run
          end
        end

        it "retains some pii attributes" do
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
          expect(claim.mobile_number).to eq claim_attributes.fetch(:mobile_number)
          expect(claim.hmrc_bank_validation_responses).to eq claim_attributes.fetch(:hmrc_bank_validation_responses)
          expect(claim.payroll_gender).to eq claim_attributes.fetch(:payroll_gender)
          expect(claim.onelogin_uid).to eq claim_attributes.fetch(:onelogin_uid)

          expect(claim.onelogin_credentials).to eq nil
          expect(claim.onelogin_idv_date_of_birth).to eq nil
          expect(claim.onelogin_idv_first_name).to eq nil
          expect(claim.onelogin_idv_full_name).to eq nil
          expect(claim.onelogin_idv_last_name).to eq nil
          expect(claim.onelogin_idv_return_codes).to eq nil
          expect(claim.onelogin_user_info).to eq nil
          expect(claim.email_address).to eq nil
          expect(claim.bank_sort_code).to be nil
          expect(claim.bank_account_number).to be nil
          expect(claim.banking_name).to be nil

          eligibility = claim.eligibility

          expect(eligibility.claimant_date_of_birth).to be nil
          expect(eligibility.claimant_national_insurance_number).to be nil
          expect(eligibility.claimant_passport_number).to be nil
          expect(eligibility.claimant_postcode).to be nil
          expect(eligibility.passport_number).to be nil
          expect(eligibility.provider_verification_claimant_date_of_birth).to be nil
          expect(eligibility.provider_verification_claimant_email).to be nil
          expect(eligibility.provider_verification_claimant_national_insurance_number).to be nil
          expect(eligibility.provider_verification_claimant_postcode).to be nil
          expect(eligibility.teacher_reference_number).to be nil
          expect(eligibility.verification).to be nil
          expect(eligibility.work_email).to be nil
          expect(eligibility.provider_assigned_to_id).to eq nil
          expect(eligibility.provider_verification_verified_by_id).to eq nil

          expect(eligibility.award_amount).to eq eligibility_attributes.fetch(:award_amount)
          expect(eligibility.building_construction_courses).to eq eligibility_attributes.fetch(:building_construction_courses)
          expect(eligibility.chemistry_courses).to eq eligibility_attributes.fetch(:chemistry_courses)
          expect(eligibility.claimant_identity_verified_at).to eq eligibility_attributes.fetch(:claimant_identity_verified_at)
          expect(eligibility.claimant_valid_passport).to eq eligibility_attributes.fetch(:claimant_valid_passport)
          expect(eligibility.computing_courses).to eq eligibility_attributes.fetch(:computing_courses)
          expect(eligibility.contract_type).to eq eligibility_attributes.fetch(:contract_type)
          expect(eligibility.early_years_courses).to eq eligibility_attributes.fetch(:early_years_courses)
          expect(eligibility.engineering_manufacturing_courses).to eq eligibility_attributes.fetch(:engineering_manufacturing_courses)
          expect(eligibility.fixed_term_full_year).to eq eligibility_attributes.fetch(:fixed_term_full_year)
          expect(eligibility.flagged_as_duplicate).to eq eligibility_attributes.fetch(:flagged_as_duplicate)
          expect(eligibility.flagged_as_mismatch_on_teaching_start_year).to eq eligibility_attributes.fetch(:flagged_as_mismatch_on_teaching_start_year)
          expect(eligibility.flagged_as_previously_start_year_matches_claim_false).to eq eligibility_attributes.fetch(:flagged_as_previously_start_year_matches_claim_false)
          expect(eligibility.further_education_teaching_start_year).to eq eligibility_attributes.fetch(:further_education_teaching_start_year)
          expect(eligibility.half_teaching_hours).to eq eligibility_attributes.fetch(:half_teaching_hours)
          expect(eligibility.hours_teaching_eligible_subjects).to eq eligibility_attributes.fetch(:hours_teaching_eligible_subjects)
          expect(eligibility.maths_courses).to eq eligibility_attributes.fetch(:maths_courses)
          expect(eligibility.physics_courses).to eq eligibility_attributes.fetch(:physics_courses)
          expect(eligibility.possible_school_id).to eq eligibility_attributes.fetch(:possible_school_id)
          expect(eligibility.provider_verification_chase_email_last_sent_at).to eq eligibility_attributes.fetch(:provider_verification_chase_email_last_sent_at)
          expect(eligibility.provider_verification_claimant_bank_details_match).to eq eligibility_attributes.fetch(:provider_verification_claimant_bank_details_match)
          expect(eligibility.provider_verification_claimant_employed_by_college).to eq eligibility_attributes.fetch(:provider_verification_claimant_employed_by_college)
          expect(eligibility.provider_verification_claimant_employment_check_declaration).to eq eligibility_attributes.fetch(:provider_verification_claimant_employment_check_declaration)
          expect(eligibility.provider_verification_completed_at).to eq eligibility_attributes.fetch(:provider_verification_completed_at)
          expect(eligibility.provider_verification_continued_employment).to eq eligibility_attributes.fetch(:provider_verification_continued_employment)
          expect(eligibility.provider_verification_contract_covers_full_academic_year).to eq eligibility_attributes.fetch(:provider_verification_contract_covers_full_academic_year)
          expect(eligibility.provider_verification_contract_type).to eq eligibility_attributes.fetch(:provider_verification_contract_type)
          expect(eligibility.provider_verification_deadline).to eq eligibility_attributes.fetch(:provider_verification_deadline)
          expect(eligibility.provider_verification_declaration).to eq eligibility_attributes.fetch(:provider_verification_declaration)
          expect(eligibility.provider_verification_disciplinary_action).to eq eligibility_attributes.fetch(:provider_verification_disciplinary_action)
          expect(eligibility.provider_verification_email_count).to eq eligibility_attributes.fetch(:provider_verification_email_count)
          expect(eligibility.provider_verification_email_last_sent_at).to eq eligibility_attributes.fetch(:provider_verification_email_last_sent_at)
          expect(eligibility.provider_verification_half_teaching_hours).to eq eligibility_attributes.fetch(:provider_verification_half_teaching_hours)
          expect(eligibility.provider_verification_half_timetabled_teaching_time).to eq eligibility_attributes.fetch(:provider_verification_half_timetabled_teaching_time)
          expect(eligibility.provider_verification_not_started_qualification_reason_other).to eq eligibility_attributes.fetch(:provider_verification_not_started_qualification_reason_other)
          expect(eligibility.provider_verification_not_started_qualification_reasons).to eq eligibility_attributes.fetch(:provider_verification_not_started_qualification_reasons)
          expect(eligibility.provider_verification_performance_measures).to eq eligibility_attributes.fetch(:provider_verification_performance_measures)
          expect(eligibility.provider_verification_started_at).to eq eligibility_attributes.fetch(:provider_verification_started_at)
          expect(eligibility.provider_verification_taught_at_least_one_academic_term).to eq eligibility_attributes.fetch(:provider_verification_taught_at_least_one_academic_term)
          expect(eligibility.provider_verification_teaching_hours_per_week).to eq eligibility_attributes.fetch(:provider_verification_teaching_hours_per_week)
          expect(eligibility.provider_verification_teaching_qualification).to eq eligibility_attributes.fetch(:provider_verification_teaching_qualification)
          expect(eligibility.provider_verification_teaching_responsibilities).to eq eligibility_attributes.fetch(:provider_verification_teaching_responsibilities)
          expect(eligibility.provider_verification_teaching_start_year).to eq eligibility_attributes.fetch(:provider_verification_teaching_start_year)
          expect(eligibility.provision_search).to eq eligibility_attributes.fetch(:provision_search)
          expect(eligibility.school_id).to eq eligibility_attributes.fetch(:school_id)
          expect(eligibility.subject_to_disciplinary_action).to eq eligibility_attributes.fetch(:subject_to_disciplinary_action)
          expect(eligibility.subject_to_formal_performance_action).to eq eligibility_attributes.fetch(:subject_to_formal_performance_action)
          expect(eligibility.subjects_taught).to eq eligibility_attributes.fetch(:subjects_taught)
          expect(eligibility.taught_at_least_one_term).to eq eligibility_attributes.fetch(:taught_at_least_one_term)
          expect(eligibility.teaching_hours_per_week).to eq eligibility_attributes.fetch(:teaching_hours_per_week)
          expect(eligibility.teaching_qualification).to eq eligibility_attributes.fetch(:teaching_qualification)
          expect(eligibility.teaching_responsibilities).to eq eligibility_attributes.fetch(:teaching_responsibilities)
          expect(eligibility.valid_passport).to eq eligibility_attributes.fetch(:valid_passport)
          expect(eligibility.work_email_verified).to eq eligibility_attributes.fetch(:work_email_verified)
        end
      end

      context "when the claim is not an inactive claim in the prior academic term" do
        around do |example|
          travel_to(AcademicYear.new(2025).start_of_autumn_term + 20.weeks) do
            claim

            perform_enqueued_jobs do
              described_class.perform_now
            end

            claim.reload

            example.run
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
