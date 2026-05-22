FactoryBot.define do
  factory :eytfi_answers, class: "Journeys::EarlyYearsTeachersFinancialIncentivePayments::SessionAnswers" do
    academic_year { AcademicYear.current }
  end
end
