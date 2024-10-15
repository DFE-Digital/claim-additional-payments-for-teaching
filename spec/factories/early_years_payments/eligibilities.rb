FactoryBot.define do
  factory :early_years_payments_eligibility, class: "Policies::EarlyYearsPayments::Eligibility" do
    trait :practitioner_claim_submitted do
      practitioner_claim_submitted_at { Time.zone.now }
    end
  end
end
