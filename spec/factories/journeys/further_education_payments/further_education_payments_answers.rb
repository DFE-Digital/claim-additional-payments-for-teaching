FactoryBot.define do
  factory :further_education_payments_answers, class: "Journeys::FurtherEducationPayments::SessionAnswers" do
    trait :with_details_from_onelogin do
      first_name { "Jo" }
      surname { "Bloggs" }
      onelogin_user_info { {email: "jo.bloggs@example.com"} }
    end

    trait :submittable do
      # FIXME implement this trait with the details required to submit a claim
    end
  end
end
