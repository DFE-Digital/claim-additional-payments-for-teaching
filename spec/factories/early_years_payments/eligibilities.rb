FactoryBot.define do
  factory :early_years_payments_eligibility, class: "Policies::EarlyYearsPayments::Eligibility" do
    trait :provider_claim_submitted do
      provider_claim_submitted_at { Time.zone.now }
    end
  end
end
