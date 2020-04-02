FactoryBot.define do
  factory :support_ticket do
    sequence(:url) { |n| "https://example.com/ticket/#{n}" }

    association :claim, factory: [:claim, :submitted]
    association :created_by, factory: :dfe_signin_user
  end
end
