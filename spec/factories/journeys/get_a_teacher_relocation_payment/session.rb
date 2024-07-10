FactoryBot.define do
  factory(
    :get_a_teacher_relocation_payment_session,
    class: "Journeys::GetATeacherRelocationPayment::Session"
  ) do
    journey { "get-a-teacher-relocation-payment" }
  end
end
