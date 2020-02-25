FactoryBot.define do
  factory :amendment do
    association :claim, factory: [:claim, :submitted]
    association :created_by, factory: :dfe_signin_user
    claim_changes { {"teacher_reference_number" => [generate(:teacher_reference_number).to_s, claim.teacher_reference_number]} }
    notes { "We couldn’t find the teacher in Teacher Pensions Service data. We contacted them in Zendesk and they told us they made a typo and gave their correct TRN" }

    trait :personal_data_removed do
      personal_data_removed_at { Time.zone.now }
      claim_changes { {"teacher_reference_number" => [generate(:teacher_reference_number).to_s, claim.teacher_reference_number], "bank_account_number" => nil} }
    end
  end
end
