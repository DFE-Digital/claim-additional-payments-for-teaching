FactoryBot.define do
  factory :early_years_payments_eligibility, class: "Policies::EarlyYearsPayments::Eligibility" do
    trait :eligible do
      start_date { 1.year.ago }
      child_facing_confirmation_given { true }
      returning_within_6_months { false }
      with_eligible_ey_provider
    end

    trait :with_eligible_ey_provider do
      nursery_urn { create(:eligible_ey_provider).urn }
    end

    trait :provider_claim_submitted do
      eligible
      provider_claim_submitted_at { Time.zone.now }
    end
  end
end
