FactoryBot.define do
  factory :further_education_payments_eligibility, class: "Policies::FurtherEducationPayments::Eligibility" do
    claim
    school { create(:school, :further_education) }

    trait :eligible do
      eligible_school
    end

    trait :eligible_school do
      association :school, factory: :fe_eligible_school
    end

    trait :verified do
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
            "email" => "seymore.skinner@springfield-elementary.edu"
          },
          "created_at" => "2024-01-01T12:00:00.000+00:00"
        }
      end
    end
  end
end
