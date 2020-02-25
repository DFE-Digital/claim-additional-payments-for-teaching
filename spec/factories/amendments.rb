FactoryBot.define do
  factory :amendment do
    association :claim, factory: [:claim, :submitted]
    association :created_by, factory: :dfe_signin_user
    claim_changes { {"teacher_reference_number" => [generate(:teacher_reference_number).to_s, claim.teacher_reference_number]} }
    notes { "We couldn’t find the teacher in Teacher Pensions Service data. We contacted them in Zendesk and they told us they made a typo and gave their correct TRN" }
  end
end
