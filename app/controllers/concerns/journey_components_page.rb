module JourneyComponentsPage
  extend ActiveSupport::Concern

  private

  def prepare_journey_components_page
    @journey_components = load_journey_components
    @reused_components = load_reused_components(@journey_components)
  end

  def load_journey_components
    Journeys.all.sort_by(&:routing_name).filter_map do |journey|
      constants = slug_constants_for(journey)
      next if constants.empty?

      {
        journey_name: formatted_journey_name(journey),
        journey_routing_name: journey.routing_name,
        constants:
      }
    end
  end

  def load_reused_components(journey_components)
    component_usage = Hash.new { |hash, key| hash[key] = [] }

    journey_components.each do |journey|
      journey_values = journey[:constants].values.flatten.uniq
      journey_values.each do |component|
        component_usage[component] << {
          journey_name: journey[:journey_name],
          journey_routing_name: journey[:journey_routing_name]
        }
      end
    end

    component_usage
      .filter_map do |component, journeys|
        next if journeys.size <= 1

        {
          component: component,
          count: journeys.size,
          journeys: journeys.sort_by { |journey| journey[:journey_name] }
        }
      end
      .sort_by { |entry| [-entry[:count], entry[:component]] }
  end

  def slug_constants_for(journey)
    journey.slug_sequence.constants(false).each_with_object({}) do |constant_name, constants|
      constant_value = journey.slug_sequence.const_get(constant_name)
      next unless constant_value.is_a?(Array)
      next unless constant_value.all? { |value| value.is_a?(String) }

      constants[constant_name.to_s] = constant_value
    end
  end

  def formatted_journey_name(journey)
    journey
      .name
      .delete_prefix("Journeys::")
      .split("::")
      .map { |part| part.titleize }
      .join(" / ")
  end
end