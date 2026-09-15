class JourneyFlowDefinition
  DEFINITION_PATH = Rails.root.join("app/models/journey_flow_definitions")
  LINK_SYMBOL = "↗".freeze
  SVG_ALLOWED_TAGS = %w[svg a polygon path rect text].freeze
  SVG_ALLOWED_ATTRIBUTES = %w[
    xmlns viewBox role aria-label class href target rel noopener noreferrer
    fill stroke stroke-width stroke-linecap stroke-linejoin text-anchor
    font-size font-family x y width height rx points d transform transform-origin
    style left top cursor
  ].freeze

  class << self
    def definition_for(journey_id)
      file_path = DEFINITION_PATH.join("#{journey_id}.yml")
      raise "Journey flow definition not found for #{journey_id}" unless file_path.exist?

      YAML.safe_load_file(file_path, permitted_classes: [Symbol], aliases: true).deep_symbolize_keys
    end

    def svg_for(journey_id)
      data = definition_for(journey_id)
      nodes = data[:nodes] || []
      edges = data[:edges] || []
      return "" if nodes.empty?

      journey = Journeys.for_routing_name(journey_id)
      depth_map = {}
      queue = []
      start_node = nodes.find { |node| node[:id].to_s == "start" } || nodes.first
      queue << start_node[:id].to_s
      depth_map[start_node[:id].to_s] = 0

      until queue.empty?
        current_id = queue.shift
        current_depth = depth_map[current_id]

        edges.each do |edge|
          next unless edge[:from].to_s == current_id

          next_id = edge[:to].to_s
          next unless depth_map[next_id].nil?

          depth_map[next_id] = current_depth + 1
          queue << next_id
        end
      end

      rows = Hash.new { |hash, key| hash[key] = [] }
      nodes.each do |node|
        node_id = node[:id].to_s
        row = depth_map[node_id] || 0
        rows[row] << node_id
      end

      box_width = 220
      box_height = 54
      padding_x = 32
      padding_y = 32
      gutter_x = 72
      gutter_y = 240
      width = ([rows.values.map(&:length).max || 1, 1].max * (box_width + gutter_x)) + padding_x * 2
      height = (rows.keys.max + 1) * (box_height + gutter_y) + padding_y * 2

      positions = {}
      rows.each do |row, ids|
        ids.each_with_index do |node_id, index|
          x = padding_x + (index * (box_width + gutter_x))
          y = padding_y + (row * (box_height + gutter_y))
          positions[node_id] = {x: x, y: y}
        end
      end

      lines = []
      lines << "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 #{width} #{height}\" role=\"img\" aria-label=\"Journey flow diagram\" class=\"journey-flow-svg\">"

      source_edge_counts = Hash.new(0)
      target_edge_counts = Hash.new(0)
      edges.each do |edge|
        source_edge_counts[edge[:from].to_s] += 1
        target_edge_counts[edge[:to].to_s] += 1
      end

      source_edge_index = Hash.new(0)
      target_edge_index = Hash.new(0)

      edges.each do |edge|
        from_id = edge[:from].to_s
        to_id = edge[:to].to_s
        from = positions[from_id]
        to = positions[to_id]
        next unless from && to

        source_index = source_edge_index[from_id]
        target_index = target_edge_index[to_id]
        source_edge_index[from_id] += 1
        target_edge_index[to_id] += 1

        from_x = from[:x] + box_width / 2
        from_y = from[:y] + box_height / 2
        to_x = to[:x] + box_width / 2
        to_y = to[:y] + box_height / 2

        source_branch_count = source_edge_counts[from_id]
        target_branch_count = target_edge_counts[to_id]
        source_lane_step = if source_branch_count >= 5
          42
        elsif source_branch_count >= 4
          36
        elsif source_branch_count >= 3
          30
        else
          18
        end
        target_lane_step = if target_branch_count >= 5
          34
        elsif target_branch_count >= 4
          28
        elsif target_branch_count >= 3
          22
        else
          12
        end
        lane_offset = ((source_index - ((source_branch_count - 1) / 2.0)) * source_lane_step) + ((target_index - ((target_branch_count - 1) / 2.0)) * target_lane_step)

        label = edge[:label].to_s
        label_x = (from_x + to_x) / 2
        label_y = (from_y + to_y) / 2 - 10 + (lane_offset / 4.0)

        if from_y == to_y
          path = "M #{from_x} #{from_y + lane_offset} L #{to_x} #{to_y + lane_offset}"
          mid_x = (from_x + to_x) / 2.0
          mid_y = (from_y + to_y) / 2.0 + lane_offset
        else
          mid_y = (from_y + to_y) / 2.0 + lane_offset
          path = "M #{from_x} #{from_y} L #{from_x} #{mid_y} L #{to_x} #{mid_y} L #{to_x} #{to_y}"
          mid_x = (from_x + to_x) / 2.0
        end

        dx = to_x - from_x
        dy = to_y - from_y
        angle = Math.atan2(dy, dx)
        arrow_size = 12
        arrow_tip_x = mid_x + (arrow_size * Math.cos(angle))
        arrow_tip_y = mid_y + (arrow_size * Math.sin(angle))
        arrow_left_x = mid_x + (arrow_size * Math.cos(angle - Math::PI / 2.5))
        arrow_left_y = mid_y + (arrow_size * Math.sin(angle - Math::PI / 2.5))
        arrow_right_x = mid_x + (arrow_size * Math.cos(angle + Math::PI / 2.5))
        arrow_right_y = mid_y + (arrow_size * Math.sin(angle + Math::PI / 2.5))

        lines << "  <path d=\"#{path}\" fill=\"none\" stroke=\"#505a5f\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\" />"
        lines << "  <polygon points=\"#{arrow_tip_x},#{arrow_tip_y} #{arrow_left_x},#{arrow_left_y} #{arrow_right_x},#{arrow_right_y}\" fill=\"#505a5f\" stroke=\"#505a5f\" stroke-width=\"1\" />"
        lines << "  <text x=\"#{label_x}\" y=\"#{label_y}\" text-anchor=\"middle\" font-size=\"12\" fill=\"#0b0c0c\">#{ERB::Util.html_escape(label)}</text>" if label.present?
      end

      nodes.each do |node|
        node_id = node[:id].to_s
        position = positions[node_id]
        next unless position

        label = humanized_label(node[:label] || node_id)
        x = position[:x]
        y = position[:y]
        href = node_url_for(journey, node_id) if journey && linkable_node?(journey, node_id)
        terminal_exit_node = terminating_exit_node?(node)
        fill = terminal_exit_node ? "#fff7f7" : "#ffffff"
        stroke = terminal_exit_node ? "#d4351c" : "#b1b4b6"
        stroke_width = terminal_exit_node ? "2" : "1.5"

        if href.present?
          lines << "  <a href=\"#{ERB::Util.html_escape(href)}\" target=\"_blank\" rel=\"noopener noreferrer\">"
        end

        lines << "  <rect x=\"#{x}\" y=\"#{y}\" width=\"#{box_width}\" height=\"#{box_height}\" rx=\"6\" fill=\"#{fill}\" stroke=\"#{stroke}\" stroke-width=\"#{stroke_width}\" />"
        lines << "  <text x=\"#{x + box_width / 2}\" y=\"#{y + box_height / 2 + 5}\" text-anchor=\"middle\" font-size=\"13\" font-family=\"Arial, sans-serif\" fill=\"#0b0c0c\">#{ERB::Util.html_escape(label)}</text>"

        if href.present?
          lines << "  </a>"
        end
      end

      lines << "</svg>"
      sanitize_svg(lines.join("\n"))
    end

    def sanitize_svg(svg)
      ActionController::Base.helpers.sanitize(svg, tags: SVG_ALLOWED_TAGS, attributes: SVG_ALLOWED_ATTRIBUTES)
    end

    def humanized_label(label)
      label.to_s.tr("-_", " ").humanize
    end

    def terminating_exit_node?(node)
      node_id = node[:id].to_s
      return true if node_id == "ineligible" || node_id.start_with?("ineligible_")
      return true if node_id == "no_work_email_access" || node_id == "claim_cancelled"

      false
    end

    def node_url_for(journey, node_id)
      node_id = node_id.to_s
      return journey.start_page_url if node_id == "start"

      slug = if node_id.start_with?("ineligible_")
        "ineligible"
      else
        node_id.tr("_", "-")
      end

      Rails.application.routes.url_helpers.admin_components_open_component_path(
        journey: journey.routing_name,
        slug: slug
      )
    end

    def linkable_node?(journey, node_id)
      node_id = node_id.to_s
      return true if node_id == "start"
      return true if node_id.start_with?("ineligible_")

      journey.slug_sequence::SLUGS.include?(node_id.tr("_", "-"))
    end
  end
end
