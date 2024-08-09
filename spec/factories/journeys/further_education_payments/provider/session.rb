FactoryBot.define do
  factory(
    :further_education_payments_provider_session,
    class: "Journeys::FurtherEducationPayments::Provider::Session"
  ) do
    journey { Journeys::FurtherEducationPayments::Provider::ROUTING_NAME }
  end
end
