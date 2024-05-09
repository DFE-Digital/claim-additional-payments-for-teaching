FactoryBot.define do
  factory :journeys_session, class: "Journeys::Session" do
    journey { "additional-payments" }
  end
end
