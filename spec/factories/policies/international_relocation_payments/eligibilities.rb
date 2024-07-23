FactoryBot.define do
  factory :international_relocation_payments_eligibility, class: "Policies::InternationalRelocationPayments::Eligibility" do
    award_amount { Policies::InternationalRelocationPayments.award_amount }

    trait :eligible_home_office do
      passport_number { Faker::Number.unique.number(digits: 9).to_s }
      nationality { "French" }
    end

    trait :eligible do
      eligible_contract
      eligible_date_of_entry
      eligible_home_office
      eligible_school
      eligible_subject
      eligible_start_date
    end

    trait :eligible_school do
      association :current_school, factory: :school
    end

    trait :eligible_date_of_entry do
      date_of_entry { 1.year.ago }
    end

    trait :eligible_contract do
      one_year { true }
    end

    trait :eligible_start_date do
      start_date { 1.month.ago }
    end

    trait :eligible_subject do
      subject { "physics" }
    end
  end
end
