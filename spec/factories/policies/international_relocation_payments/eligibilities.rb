FactoryBot.define do
  factory :international_relocation_payments_eligibility, class: "Policies::InternationalRelocationPayments::Eligibility" do
    trait :eligible_home_office do
      passport_number { "123456789" }
      nationality { "French" }
    end

    trait :eligible do
      eligible_home_office
      eligible_school
    end

    trait :eligible_school do
      association :current_school, factory: :school
    end
  end
end
