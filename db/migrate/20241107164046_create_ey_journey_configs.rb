class CreateEyJourneyConfigs < ActiveRecord::Migration[7.0]
  def up
    [
      Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME,
      Journeys::EarlyYearsPayment::Provider::Authenticated::ROUTING_NAME,
      Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME
    ].reject do |routing_name|
      Journeys::Configuration.exists?(routing_name: routing_name)
    end.each do |routing_name|
      Journeys::Configuration.create!(
        routing_name: routing_name,
        current_academic_year: AcademicYear.current,
        open_for_submissions: false
      )
    end
  end

  def down
    [
      Journeys::EarlyYearsPayment::Provider::Start::ROUTING_NAME,
      Journeys::EarlyYearsPayment::Provider::Authenticated::ROUTING_NAME,
      Journeys::EarlyYearsPayment::Practitioner::ROUTING_NAME
    ].each do |routing_name|
      Journeys::Configuration.find_by(routing_name: routing_name)&.destroy
    end
  end
end
