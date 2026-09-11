class JourneyFlowDefinition
  DEFINITION_PATH = Rails.root.join("app/models/journey_flow_definitions")
  LINK_SYMBOL = "↗".freeze

  class << self
    def definition_for(journey_id)
      file_path = DEFINITION_PATH.join("#{journey_id}.yml")
      raise "Journey flow definition not found for #{journey_id}" unless file_path.exist?

      YAML.safe_load_file(file_path, permitted_classes: [Symbol], aliases: true).deep_symbolize_keys
    end

    def mermaid_for(journey_id)
      data = definition_for(journey_id)
      journey = Journeys.for_routing_name(journey_id)
      raise "Journey not found for #{journey_id}" if journey.blank?

      lines = ["flowchart TD"]

      data[:nodes].each do |node|
        node_id = node[:id].to_s
        label = humanized_label(node[:label] || node_id)
        lines << "    #{node_id}[#{label} #{LINK_SYMBOL}]"
      end

      data[:edges].each do |edge|
        label = edge[:label].present? ? "|#{edge[:label]}|" : ""
        lines << "    #{edge[:from]} --> #{label} #{edge[:to]}"
      end

      data[:nodes].each do |node|
        lines << "    click #{node[:id]} href \"#{node_url_for(journey, node[:id])}\""
      end

      lines.join("\n")
    end

    def humanized_label(label)
      label.to_s.tr("-_", " ").humanize
    end

    def node_url_for(journey, node_id)
      return journey.start_page_url if node_id.to_s == "start"

      slug = node_id.to_s.tr("_", "-")

      Rails.application.routes.url_helpers.admin_components_open_component_path(
        journey: journey.routing_name,
        slug: slug
      )
    end
  end
end
