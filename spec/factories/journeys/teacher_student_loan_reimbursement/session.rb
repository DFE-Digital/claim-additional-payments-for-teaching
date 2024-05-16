FactoryBot.define do
  factory :student_loans_session, class: "Journeys::TeacherStudentLoanReimbursement::Session" do
    journey { "student-loans" }
  end
end
