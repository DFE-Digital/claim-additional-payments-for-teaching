FactoryBot.define do
  factory :service_access_code, class: "Journeys::ServiceAccessCode" do
    journey { Journeys::FurtherEducationPayments }
    used { false }
  end
end
