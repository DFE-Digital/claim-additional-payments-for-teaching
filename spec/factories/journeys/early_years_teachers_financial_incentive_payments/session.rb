FactoryBot.define do
  factory :eytfi_session, class: "Journeys::EarlyYearsTeachersFinancialIncentivePayments::Session" do
    journey { Journeys::EarlyYearsTeachersFinancialIncentivePayments.routing_name }
  end
end
