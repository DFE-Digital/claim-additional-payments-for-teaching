FactoryBot.define do
  factory :further_education_payments_session, class: "Journeys::FurtherEducationPayments::Session" do
    journey { Journeys::FurtherEducationPayments.routing_name }
  end
end
