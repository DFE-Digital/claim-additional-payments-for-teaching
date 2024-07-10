FactoryBot.define do
  factory :further_education_payments_session, class: "Journeys::FurtherEducationPayments::Session" do
    journey { Journeys::FurtherEducationPayments::ROUTING_NAME }
  end
end
