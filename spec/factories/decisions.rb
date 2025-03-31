FactoryBot.define do
  factory :decision do
    association :created_by, factory: :dfe_signin_user
    claim { build(:claim, :submitted) }

    trait :approved do
      approved { true }
    end

    trait :rejected do
      approved { false }
      rejected_reasons { {policy::ADMIN_DECISION_REJECTED_REASONS.first => "1"} }
    end

    trait :with_notes do
      notes { "Some notes" }
    end

    trait :undone do
      undone { true }
    end

    trait :auto_approved do
      approved { true }
      created_by_id { nil }
      notes { "Auto-approved" }
    end
  end
end
