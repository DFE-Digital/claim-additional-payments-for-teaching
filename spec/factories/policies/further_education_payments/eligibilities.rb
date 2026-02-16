FactoryBot.define do
  factory :further_education_payments_eligibility, class: "Policies::FurtherEducationPayments::Eligibility" do
    school { create(:school, :further_education) }

    trait :eligible do
      eligible_school
      contract_type { "permanent" }
      teaching_responsibilities { true }
      teaching_qualification { "yes" }
      further_education_teaching_start_year { "2023" }
      teaching_hours_per_week { "more_than_12" }
      hours_teaching_eligible_subjects { false }
      half_teaching_hours { true }
      subjects_taught { ["maths", "physics"] }
      maths_courses { ["approved_level_321_maths", "gcse_maths"] }
      physics_courses { ["gcse_physics"] }
      subject_to_formal_performance_action { false }
      subject_to_disciplinary_action { false }
    end

    trait :eligible_school do
      association :school, factory: :fe_eligible_school
    end

    trait :duplicate do
      flagged_as_duplicate { true }
    end

    trait :year_one_verified do
      verification do
        {
          "assertions" => [
            {
              "name" => "contract_type",
              "outcome" => true
            },
            {
              "name" => "teaching_responsibilities",
              "outcome" => true
            },
            {
              "name" => "further_education_teaching_start_year",
              "outcome" => true
            },
            {
              "name" => "teaching_hours_per_week",
              "outcome" => true
            },
            {
              "name" => "half_teaching_hours",
              "outcome" => false
            },
            {
              "name" => "subjects_taught",
              "outcome" => false
            }
          ],
          "verifier" => {
            "dfe_sign_in_uid" => "123",
            "first_name" => "Seymoure",
            "last_name" => "Skinner",
            "email" => "seymore.skinner@springfield-elementary.edu",
            "dfe_sign_in_organisation_name" => "Springfield Elementary",
            "dfe_sign_in_role_codes" => ["teacher_payments_claim_verifier"]
          },
          "created_at" => "2024-01-01T12:00:00.000+00:00"
        }
      end
    end

    trait :year_one_verified_variable_hours do
      contract_type { "variable_hours" }
      teaching_responsibilities { true }
      further_education_teaching_start_year { "2023" }
      teaching_hours_per_week { "more_than_12" }
      hours_teaching_eligible_subjects { false }
      half_teaching_hours { true }
      subjects_taught { ["maths", "physics"] }
      maths_courses { ["approved_level_321_maths", "gcse_maths"] }
      physics_courses { ["gcse_physics"] }
      taught_at_least_one_term { true }
      verification do
        {
          "assertions" => [
            {
              "name" => "contract_type",
              "outcome" => true
            },
            {
              "name" => "teaching_responsibilities",
              "outcome" => true
            },
            {
              "name" => "further_education_teaching_start_year",
              "outcome" => true
            },
            {
              "name" => "taught_at_least_one_term",
              "outcome" => true
            },
            {
              "name" => "teaching_hours_per_week",
              "outcome" => true
            },
            {
              "name" => "half_teaching_hours",
              "outcome" => true
            },
            {
              "name" => "subjects_taught",
              "outcome" => true
            }
          ],
          "verifier" => {
            "dfe_sign_in_uid" => "123",
            "first_name" => "Seymoure",
            "last_name" => "Skinner",
            "email" => "seymore.skinner@springfield-elementary.edu",
            "dfe_sign_in_organisation_name" => "Springfield Elementary",
            "dfe_sign_in_role_codes" => ["teacher_payments_claim_verifier"]
          },
          "created_at" => "2024-01-01T12:00:00.000+00:00"
        }
      end
    end

    trait :year_one_verified_teaching_start_year_false do
      verification do
        {
          "assertions" => [
            {
              "name" => "contract_type",
              "outcome" => true
            },
            {
              "name" => "teaching_responsibilities",
              "outcome" => true
            },
            {
              "name" => "further_education_teaching_start_year",
              "outcome" => false
            },
            {
              "name" => "teaching_hours_per_week",
              "outcome" => true
            },
            {
              "name" => "half_teaching_hours",
              "outcome" => true
            },
            {
              "name" => "subjects_taught",
              "outcome" => true
            }
          ],
          "verifier" => {
            "dfe_sign_in_uid" => "123",
            "first_name" => "Seymoure",
            "last_name" => "Skinner",
            "email" => "seymore.skinner@springfield-elementary.edu",
            "dfe_sign_in_organisation_name" => "Springfield Elementary",
            "dfe_sign_in_role_codes" => ["teacher_payments_claim_verifier"]
          },
          "created_at" => "2024-01-01T12:00:00.000+00:00"
        }
      end
    end

    trait :with_trn do
      teacher_reference_number { generate(:teacher_reference_number) }
    end

    trait :identity_verified_by_provider do
      claimant_date_of_birth { Date.new(1990, 1, 1) }
      claimant_postcode { "SW1A 1AA" }
      claimant_national_insurance_number { "AB123456C" }
      claimant_valid_passport { true }
      claimant_passport_number { "123456789" }
      claimant_identity_verified_at { Time.zone.now }
    end

    trait :provider_verifiable do
      provider_verification_teaching_responsibilities { true }
      provider_verification_teaching_start_year_matches_claim { true }
      provider_verification_teaching_qualification { "yes" }
      provider_verification_contract_type { "fixed_term" }
      provider_verification_contract_covers_full_academic_year { true }
      provider_verification_taught_at_least_one_academic_term { nil }
      provider_verification_performance_measures { false }
      provider_verification_disciplinary_action { false }
      provider_verification_teaching_hours_per_week { "more_than_20" }
      provider_verification_half_teaching_hours { true }
      provider_verification_half_timetabled_teaching_time { true }
      provider_verification_continued_employment { true }
    end

    trait :provider_verification_started do
      provider_verification_started_at { Time.zone.now }
    end

    trait :provider_verification_completed do
      provider_verifiable
      provider_verification_declaration { true }
      provider_verification_completed_at { Time.zone.now }
      provider_verification_verified_by_id { create(:dfe_signin_user).id }
    end

    trait :with_award_amount do
      award_amount { [2_000, 2_500, 3_000, 4_000, 5_000, 6_000].sample }
    end

    trait :provider_verification_employment_checked do
      provider_verification_claimant_employed_by_college { true }
      provider_verification_claimant_date_of_birth { Date.new(1990, 1, 1) }
      provider_verification_claimant_national_insurance_number { "AB123456C" }
      provider_verification_claimant_postcode { "TE57 1NG" }
      provider_verification_claimant_bank_details_match { true }
      provider_verification_claimant_email { "test@example.com" }
      provider_verification_claimant_employment_check_declaration { true }
    end

    trait :provider_verification_employment_checked_claimant_not_employed_by_college do
      provider_verification_claimant_employed_by_college { false }
      provider_verification_claimant_date_of_birth { nil }
      provider_verification_claimant_national_insurance_number { nil }
      provider_verification_claimant_postcode { nil }
      provider_verification_claimant_bank_details_match { nil }
      provider_verification_claimant_email { nil }
      provider_verification_claimant_employment_check_declaration { nil }
      provider_verification_completed_at { Time.zone.now }
      provider_verification_verified_by_id { create(:dfe_signin_user).id }
    end
  end
end
