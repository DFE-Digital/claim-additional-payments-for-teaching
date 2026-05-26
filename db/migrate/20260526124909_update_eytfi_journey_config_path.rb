class UpdateEytfiJourneyConfigPath < ActiveRecord::Migration[8.1]
  def change
    journey_config = Journeys::Configuration.find_by(
      routing_name: "early-years-teachers-financial-incentive-payments"
    )

    journey_config&.update(
      routing_name: "early-years-teachers-recognition-payments"
    )
  end
end
