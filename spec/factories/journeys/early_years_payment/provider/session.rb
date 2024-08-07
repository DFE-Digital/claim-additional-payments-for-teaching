FactoryBot.define do
  factory :early_years_payment_provider_session, class: "Journeys::EarlyYearsPayment::Provider::Session" do
    journey { Journeys::EarlyYearsPayment::Provider::ROUTING_NAME }
  end
end
