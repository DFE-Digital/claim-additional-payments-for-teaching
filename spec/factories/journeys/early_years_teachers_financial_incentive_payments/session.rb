FactoryBot.define do
  factory(
    :early_years_teachers_financial_incentive_payments_session,
    class: "Journeys::EarlyYearsTeachersFinancialIncentivePayments::Session"
  ) do
    journey { Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name }
  end
end
