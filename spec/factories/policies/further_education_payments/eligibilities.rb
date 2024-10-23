FactoryBot.define do
  factory :further_education_payments_eligibility, class: "Policies::FurtherEducationPayments::Eligibility" do
    claim
    school { create(:school, :further_education) }

    trait :eligible do
      eligible_school
      contract_type { "permanent" }
      verified
    end

    trait :not_verified do
      eligible_school
      contract_type { "permanent" }
    end

    trait :eligible_school do
      association :school, factory: :fe_eligible_school
    end

    trait :duplicate do
      flagged_as_duplicate { true }
    end

    trait :verified do
      contract_type { "permanent" }
      teaching_responsibilities { true }
      further_education_teaching_start_year { "2023" }
      teaching_hours_per_week { "more_than_12" }
      hours_teaching_eligible_subjects { false }
      half_teaching_hours { true }
      subjects_taught { ["maths", "physics"] }
      maths_courses { ["approved_level_321_maths", "gcse_maths"] }
      physics_courses { ["gcse_physics"] }
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

    trait :verified_variable_hours do
      contract_type { "variable_hours" }
      teaching_responsibilities { true }
      further_education_teaching_start_year { "2023" }
      teaching_hours_per_week { "more_than_12" }
      hours_teaching_eligible_subjects { false }
      half_teaching_hours { true }
      subjects_taught { ["maths", "physics"] }
      maths_courses { ["approved_level_321_maths", "gcse_maths"] }
      physics_courses { ["gcse_physics"] }
      teaching_hours_per_week_next_term { "at_least_2_5" }
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
            },
            {
              "name" => "teaching_hours_per_week_next_term",
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

    trait :with_trn do
      eligible
      teacher_reference_number { generate(:teacher_reference_number) }
    end
  end
end
