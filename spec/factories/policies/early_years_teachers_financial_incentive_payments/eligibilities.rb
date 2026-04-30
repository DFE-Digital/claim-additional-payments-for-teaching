FactoryBot.define do
  factory(
    :early_years_teachers_financial_incentive_payments_eligibility,
    class: "Policies::EarlyYearsTeachersFinancialIncentivePayments::Eligibility"
  ) do
    trait :eligible do
    end
  end
end
