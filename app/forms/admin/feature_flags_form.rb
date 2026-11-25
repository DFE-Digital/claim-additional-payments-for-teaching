module Admin
  class FeatureFlagsForm
    def self.for_journey_configuration(journey_configuration)
      case journey_configuration.routing_name
      when "further-education-payments"
        form = FeFeatureFlagsForm.new
        form.load_data
        form
      when "targeted-retention-incentive-payments"
        form = StriFeatureFlagsForm.new
        form.load_data
        form
      end
    end
  end
end
