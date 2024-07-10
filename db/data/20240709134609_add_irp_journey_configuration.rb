# Run me with `rails runner db/data/20240709134609_add_irp_journey_configuration.rb`

Journeys::Configuration.create!(
  routing_name: Journeys::GetATeacherRelocationPayment::ROUTING_NAME,
  current_academic_year: AcademicYear.current
)
