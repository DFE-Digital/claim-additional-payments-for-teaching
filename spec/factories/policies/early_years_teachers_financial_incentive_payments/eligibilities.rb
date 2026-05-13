FactoryBot.define do
  factory(
    :early_years_teachers_financial_incentive_payments_eligibility,
    class: "Policies::EarlyYearsTeachersFinancialIncentivePayments::Eligibility"
  ) do
    eligible_eytfi_provider_urn { "EY12345" }

    trait :with_provider do
      after(:build) do |eligibility|
        create(
          :eligible_eytfi_provider,
          name: "TESTTESTTEST",
          urn: eligibility.eligible_eytfi_provider_urn
        )
      end
    end

    trait :eligible do
      with_provider
    end
  end
end
