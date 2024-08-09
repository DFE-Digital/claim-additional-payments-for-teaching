FactoryBot.define do
  factory :further_education_payments_eligibility, class: "Policies::FurtherEducationPayments::Eligibility" do
    school { create(:school, :further_education) }

    trait :eligible do
    end
  end
end
