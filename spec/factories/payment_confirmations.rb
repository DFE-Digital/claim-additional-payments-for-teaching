FactoryBot.define do
  factory :payment_confirmation do
    association :created_by, factory: :dfe_signin_user
  end
end
