FactoryBot.define do
  factory :decision do
    association :created_by, factory: :dfe_signin_user
    claim { build(:claim, :submitted) }
    trait :approved do
      result { :approved }
    end

    trait :rejected do
      result { :rejected }
    end

    trait :undone do
      undone { true }
    end
  end
end
