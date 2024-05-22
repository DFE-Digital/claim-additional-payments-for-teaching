FactoryBot.define do
  factory :additional_payments_session, class: "Journeys::AdditionalPaymentsForTeaching::Session" do
    journey { "additional-payments" }
  end
end
