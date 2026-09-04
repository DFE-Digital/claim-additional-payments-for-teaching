require "rails_helper"

RSpec.describe Policies::DataRetention::PoliciesJob do
  before do
    FeatureFlag.enable!(:apply_data_retention_policy)
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

    context "when the claim is more than 6 academic years old" do
      before do |example|
        travel_to(Time.utc(2031, 9, 1, 12, 0, 0)) do
          claim

          perform_enqueued_jobs do
            described_class.perform_now
          end

          claim.reload
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
        expect(claim.payroll_gender).to eq claim_attributes.fetch(:payroll_gender)
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

        expect(eligibility.provider_verification_verified_by_id).to eq eligibility_attributes.fetch(:provider_verification_verified_by_id)
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
        before do |example|
          travel_to(Time.utc(2026, 9, 1, 12, 0, 0)) do
            claim

            perform_enqueued_jobs do
              described_class.perform_now
            end

            claim.reload
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
          expect(claim.mobile_number).to be nil
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
          expect(claim.bank_sort_code).to eq claim_attributes.fetch(:bank_sort_code)
          expect(claim.bank_account_number).to eq claim_attributes.fetch(:bank_account_number)
          expect(claim.banking_name).to eq claim_attributes.fetch(:banking_name)

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
          expect(eligibility.teacher_reference_number).to eq eligibility_attributes.fetch(:teacher_reference_number)
          expect(eligibility.verification).to be nil
          expect(eligibility.work_email).to be nil
          expect(eligibility.provider_assigned_to_id).to eq nil

          expect(eligibility.provider_verification_verified_by_id).to eq eligibility_attributes.fetch(:provider_verification_verified_by_id)
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

    context "scrubbing after 6 years when the claim has already been scrubbed" do
      before do |example|
        travel_to(Time.utc(2026, 9, 1, 12, 0, 0)) do
          claim

          perform_enqueued_jobs do
            described_class.perform_now
          end

          claim.reload
        end

        travel_to(Time.utc(2031, 9, 1, 12, 0, 0)) do
          claim

          perform_enqueued_jobs do
            described_class.perform_now
          end

          claim.reload
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
        expect(claim.payroll_gender).to eq claim_attributes.fetch(:payroll_gender)
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

        expect(eligibility.provider_verification_verified_by_id).to eq eligibility_attributes.fetch(:provider_verification_verified_by_id)
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
  end
end
