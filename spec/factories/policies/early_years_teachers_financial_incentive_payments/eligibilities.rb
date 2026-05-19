FactoryBot.define do
  factory(
    :early_years_teachers_financial_incentive_payments_eligibility,
    class: "Policies::EarlyYearsTeachersFinancialIncentivePayments::Eligibility"
  ) do
    transient do
      eligible_eytfi_provider { create(:eligible_eytfi_provider) }
    end

    eligible_eytfi_provider_urn { eligible_eytfi_provider.urn }

    trait :eligible do
    end
  end
end
