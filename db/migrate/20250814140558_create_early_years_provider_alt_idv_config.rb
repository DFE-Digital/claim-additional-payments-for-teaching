class CreateEarlyYearsProviderAltIdvConfig < ActiveRecord::Migration[8.0]
  def up
    Journeys::Configuration.create!(
      routing_name: Journeys::EarlyYearsPayment::Provider::AlternativeIdv::ROUTING_NAME,
      current_academic_year: AcademicYear.current,
      open_for_submissions: false
    )
  end

  def down
    Journeys::Configuration.find_by(
      routing_name: Journeys::EarlyYearsPayment::Provider::AlternativeIdv::ROUTING_NAME
    )&.destroy
  end
end
