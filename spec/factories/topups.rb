FactoryBot.define do
  factory :topup do
    claim
    association :created_by, factory: :dfe_signin_user
    award_amount { 100.00 }
  end
end
