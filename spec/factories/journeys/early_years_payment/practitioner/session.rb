FactoryBot.define do
  factory :early_years_payment_practitioner_session, class: "Journeys::EarlyYearsPayment::Practitioner::Session" do
    journey { Journeys::EarlyYearsPayment::Practitioner.routing_name }
  end
end
