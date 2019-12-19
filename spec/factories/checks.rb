FactoryBot.define do
  factory :check do
    association :checked_by, factory: :dfe_signin_user
    claim { build(:claim, :submitted) }
    trait :approved do
      result { :approved }
    end

    trait :rejected do
      result { :rejected }
    end
  end
end
