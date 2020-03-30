FactoryBot.define do
  factory :note do
    sequence(:body) { |n| "Note about the claim #{n}" }

    association :claim, factory: [:claim, :submitted]
    association :created_by, factory: :dfe_signin_user
  end
end
