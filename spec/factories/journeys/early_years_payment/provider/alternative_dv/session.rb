FactoryBot.define do
  factory(
    :early_years_payment_provider_alternative_idv_session,
    class: "Journeys::EarlyYearsPayment::Provider::AlternativeIdv::Session"
  ) do
    journey { Journeys::EarlyYearsPayment::Provider::AlternativeIdv::ROUTING_NAME }
  end
end
