FactoryBot.define do
  sequence(:email_address) { |n| "person#{n}@example.com" }
  sequence(:teacher_reference_number, 1000000) { |n| n }
  sequence(:national_insurance_number, 100000) { |n| "QQ#{n}C" }

  factory :claim do
    started_at { Time.zone.now }

    transient do
      policy { Policies::StudentLoans }
      eligibility_factory { :"#{policy.to_s.underscore}_eligibility" }
      eligibility_trait { nil }
      eligibility_attributes { nil }
      decision_creator { nil }
      rejected_reasons { nil }
      using_mobile_number_from_tid { false }
    end

    after(:build) do |claim, evaluator|
      journey = Journeys.for_policy(evaluator.policy)

      begin
        raise ActiveRecord::RecordNotFound unless Journeys.for_policy(evaluator.policy)&.configuration.present?
      rescue ActiveRecord::RecordNotFound
        create(:journey_configuration, journey::I18N_NAMESPACE)
      end

      claim.eligibility = build(evaluator.eligibility_factory, evaluator.eligibility_trait, **evaluator.eligibility_attributes || {}) unless claim.eligibility

      raise "Policy of Claim (#{evaluator.policy}) must match Eligibility class (#{claim.eligibility.policy})" if evaluator.policy != claim.eligibility.policy

      claim_academic_year =
        if [Policies::EarlyCareerPayments, Policies::LevellingUpPremiumPayments].include?(evaluator.policy)
          Journeys::AdditionalPaymentsForTeaching.configuration.current_academic_year
        elsif evaluator.policy == Policies::FurtherEducationPayments
          Journeys::FurtherEducationPayments.configuration.current_academic_year
        else
          AcademicYear::Type.new.serialize(AcademicYear.new(2019))
        end

      claim.academic_year = claim_academic_year unless claim.academic_year_before_type_cast
    end

    trait :current_academic_year do
      academic_year { AcademicYear.current }
    end

    trait :with_onelogin_idv_data do
      identity_confirmed_with_onelogin { true }
      onelogin_uid { SecureRandom.uuid }
      onelogin_auth_at { rand(14.days.ago..1.day.ago).to_datetime }
      onelogin_idv_at { (onelogin_auth_at + 1.hour) }
      onelogin_idv_first_name { first_name }
      onelogin_idv_last_name { surname }
      onelogin_idv_date_of_birth { date_of_birth }
    end

    trait :with_details_from_dfe_identity do
      first_name { "Jo" }
      surname { "Bloggs" }
      date_of_birth { 20.years.ago.to_date }
      national_insurance_number { generate(:national_insurance_number) }
    end

    trait :eligible do
      eligibility_trait { :eligible }
    end

    trait :submittable do
      eligible
      with_details_from_dfe_identity
      with_student_loan
      with_bank_details
      bank_details_validated

      address_line_1 { "1 Test Road" }
      postcode { "WIA OAA" }
      email_address { generate(:email_address) }
      email_verified { true }
      payroll_gender { :female }
      provide_mobile_number { false }
      details_check { true }

      after(:build) do |claim, evaluator|
        if claim.has_ecp_or_lupp_policy?
          claim.provide_mobile_number = true
          claim.mobile_number = "07474000123"
          claim.mobile_verified = true
          if evaluator.using_mobile_number_from_tid
            claim.mobile_check = "use"
            claim.mobile_verified = false
            claim.logged_in_with_tid = true
          end
        end
      end
    end

    trait :submitted do
      submittable
      submitted_at { Time.zone.now }
      reference { Reference.new.to_s }
    end

    trait :policy_options_provided_with_both do
      policy_options_provided {
        [
          {"policy" => "EarlyCareerPayments", "award_amount" => "2000.0"},
          {"policy" => "LevellingUpPremiumPayments", "award_amount" => "2000.0"}
        ]
      }
    end

    trait :policy_options_provided_ecp_only do
      policy_options_provided {
        [
          {"policy" => "EarlyCareerPayments", "award_amount" => "2000.0"}
        ]
      }
    end

    trait :policy_options_provided_lup_only do
      policy_options_provided {
        [
          {"policy" => "LevellingUpPremiumPayments", "award_amount" => "2000.0"}
        ]
      }
    end

    trait :verified do
      govuk_verify_fields { %w[first_name surname address_line_1 postcode date_of_birth payroll_gender] }
    end

    trait :unverified do
      submitted

      govuk_verify_fields { [] }
    end

    trait :auto_approved do
      submitted
      after(:build) do |claim, _|
        create(:decision, :auto_approved, claim: claim)
      end
    end

    trait :approved do
      submitted
      after(:build) do |claim, evaluator|
        if evaluator.decision_creator
          create(:decision, claim: claim, result: "approved", created_by: evaluator.decision_creator)
        else
          create(:decision, claim: claim, result: "approved")
        end
      end
    end

    trait :payrollable do
      approved
    end

    trait :rejected do
      submitted
      after(:build) do |claim, evaluator|
        claim.save
        if evaluator.rejected_reasons
          create(:decision, :rejected, claim: claim, rejected_reasons: evaluator.rejected_reasons)
        else
          create(:decision, :rejected, claim: claim)
        end
      end
    end

    trait :ineligible do
      submittable

      eligibility_trait { :ineligible }
    end

    trait :personal_data_removed do
      submitted
      first_name { nil }
      middle_name { nil }
      surname { nil }
      date_of_birth { nil }
      address_line_1 { nil }
      address_line_2 { nil }
      address_line_3 { nil }
      address_line_4 { nil }
      postcode { nil }
      payroll_gender { nil }
      national_insurance_number { nil }
      bank_sort_code { nil }
      bank_account_number { nil }
      building_society_roll_number { nil }
      personal_data_removed_at { Time.zone.now }
    end

    trait :with_student_loan do
      has_student_loan { true }
      student_loan_plan { StudentLoan::PLAN_1 }
    end

    trait :with_no_student_loan do
      has_student_loan { false }
      student_loan_plan { nil }
    end

    trait :first_lup_claim_year do
      academic_year { AcademicYear::Type.new.serialize(AcademicYear.new(2022)) }
    end

    trait :held do
      held { true }
    end

    trait :flagged_for_qa do
      qa_required { true }
      qa_completed_at { nil }
    end

    trait :qa_completed do
      qa_required { true }
      qa_completed_at { Time.zone.now }
    end

    trait :with_bank_details do
      bank_or_building_society { :personal_bank_account }
      banking_name { "Jo Bloggs" }
      bank_sort_code { rand(100000..999999) }
      bank_account_number { rand(10000000..99999999) }
    end

    trait :bank_details_validated do
      hmrc_bank_validation_succeeded { true }
      hmrc_bank_validation_responses do
        [
          {code: 200, body: "Test response"}
        ]
      end
    end

    trait :bank_details_not_validated do
      hmrc_bank_validation_succeeded { false }
      hmrc_bank_validation_responses do
        [
          {code: 429, body: "Test failure"},
          {code: 200, body: "Test response"},
          {code: 200, body: "Test response"}
        ]
      end
    end

    trait :with_valid_teacher_id_user_info do
      teacher_id_user_info do
        {
          "given_name" => "John",
          "family_name" => "Doe",
          "trn" => "123456",
          "birthdate" => "1990-01-01",
          "ni_number" => "AB123456C",
          "trn_match_ni_number" => "True",
          "email" => "john.doe@example.com"
        }
      end
    end

    trait :with_invalid_teacher_id_user_info do
      teacher_id_user_info do
        {
          "given_name" => "John",
          "family_name" => "Doe",
          "trn" => "123456",
          "birthdate" => "1990-01-01",
          "ni_number" => "AB123456C",
          "trn_match_ni_number" => "False"
        }
      end
    end

    trait :skipped_tid do
      teacher_id_user_info { {} }
      details_check { nil }
      logged_in_with_tid { nil }
    end

    trait :logged_in_with_tid do
      logged_in_with_tid { true }
    end

    trait :has_amendments do
      after(:create) do |claim, _|
        create_list(:amendment, 2, claim:)
      end
    end

    trait :has_all_passed_tasks do
      after(:create) do |claim, _|
        ClaimCheckingTasks.new(claim).applicable_task_names.map do |task|
          create(:task, :automated, :passed, name: task, claim:)
        end
      end
    end

    trait :has_notes do
      after(:create) do |claim, _|
        create_list(:note, 2, claim:)
      end
    end

    trait :has_support_ticket do
      after(:create) do |claim, _|
        create(:support_ticket, claim:)
      end
    end

    trait :awaiting_provider_verification do
      eligibility_trait { :not_verified }

      after(:create) do |claim, _|
        create(:note, claim:, label: "provider_verification")
      end
    end

    trait :with_dqt_teacher_status do
      dqt_teacher_status do
        {
          trn: 123456,
          ni_number: "AB123123A",
          name: "Rick Sanchez",
          dob: "66-06-06T00:00:00",
          active_alert: false,
          state: 0,
          state_name: "Active",
          qualified_teacher_status: {
            name: "Qualified teacher (trained)",
            qts_date: "2018-12-01",
            state: 0,
            state_name: "Active"
          },
          induction: {
            start_date: "2021-07-01T00:00:00Z",
            completion_date: "2021-07-05T00:00:00Z",
            status: "Pass",
            state: 0,
            state_name: "Active"
          },
          initial_teacher_training: {
            programme_start_date: "666-06-06T00:00:00",
            programme_end_date: "2021-07-04T00:00:00Z",
            programme_type: "Overseas Trained Teacher Programme",
            result: "Pass",
            subject1: "mathematics",
            subject1_code: "G100",
            subject2: nil,
            subject2_code: nil,
            subject3: nil,
            subject3_code: nil,
            qualification: "BA (Hons)",
            state: 0,
            state_name: "Active"
          },
          qualifications: [
            {
              he_subject1_code: "G100"
            }
          ]
        }
      end
    end
  end
end
