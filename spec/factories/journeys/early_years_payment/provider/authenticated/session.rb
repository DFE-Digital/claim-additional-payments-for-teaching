FactoryBot.define do
  factory :early_years_payment_provider_authenticated_session, class: "Journeys::EarlyYearsPayment::Provider::Authenticated::Session" do
    journey { Journeys::EarlyYearsPayment::Provider::Authenticated::ROUTING_NAME }
  end
end
