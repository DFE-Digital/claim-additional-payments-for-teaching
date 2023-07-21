FactoryBot.define do
  factory :payment_confirmation do
    association :created_by, factory: :dfe_signin_user
    scheduled_payment_date { Date.today }
  end
end
