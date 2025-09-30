require "rails_helper"

RSpec.describe "analytics manifest" do
  it "has every field annotated" do
    File.open(Rails.root.join("config/analytics.yml")).readlines.each_with_index do |line, index|
      next unless line.match?(/^\s*-\s/)

      line_number = index + 1

      permitted_types = %w[string boolean datetime date uuid integer float jsonb decimal]

      match = line.match(/^\s*-\s(\S*)\s#\s(\S+),\s(.+)/)

      unless match
        raise "config/analytics.yml:#{line_number} missing or incorrect annotation syntax"
      end

      unless permitted_types.include?(match[2])
        raise "config/analytics.yml:#{line_number} unexpected type #{match[2]}, permitted types: #{permitted_types}"
      end
    end
  end
end
