FactoryBot.define do
  factory :early_years_payment_provider_start_session, class: "Journeys::EarlyYearsPayment::Provider::Start::Session" do
    journey { Journeys::EarlyYearsPayment::Provider::Start.routing_name }
  end
end
