FactoryBot.define do
  factory :early_years_payment_start_session, class: "Journeys::EarlyYearsPayment::Start::Session" do
    journey { Journeys::EarlyYearsPayment::Start::ROUTING_NAME }
  end
end
