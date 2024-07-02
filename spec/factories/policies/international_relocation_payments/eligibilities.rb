FactoryBot.define do
  factory :international_relocation_payments_eligibility, class: "Policies::InternationalRelocationPayments::Eligibility" do
    trait :eligible_home_office do
      passport_number { "123456789" }
      nationality { "French" }
    end

    trait :eligible do
      eligible_home_office
      eligible_school

      application_route { "teacher" }
      state_funded_secondary_school { true }
      one_year { true }
      start_date { Date.tomorrow }
      subject { "physics" }
      visa_type { "British National (Overseas) visa" }
      date_of_entry { start_date - 1.week }
    end

    trait :eligible_school do
      association :current_school, factory: :school
    end
  end
end
