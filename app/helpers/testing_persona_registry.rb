require "yaml"

module TestingPersonaRegistry
  class << self
    def testing_personas
      return [] if Rails.env.production? && !Rails.env.review_app_like?

      YAML.safe_load_file(
        Rails.root.join("config/testing_personas.yml"),
        permitted_classes: [Date, Time],
        aliases: true
      ).map { |persona| normalize_persona(persona) }
    end

    def validate_personas!(personas: testing_personas)
      personas.each do |persona|
        spec_path = Rails.root.join(persona[:spec].to_s)
        raise "Testing persona spec missing: #{persona[:spec]}" unless spec_path.exist?

        next if File.read(spec_path).include?(persona[:title].to_s)

        raise "Title drift: '#{persona[:title]}' was not found in #{persona[:spec]}"
      end

      true
    end

    private

    def normalize_persona(persona)
      journey = persona["journey"]
      journey = journey.safe_constantize if journey.is_a?(String)

      {
        title: persona["title"],
        outcome: persona["outcome"],
        acceptance_criteria: persona["criteria"],
        description: persona["description"],
        scenario: persona["scenario"],
        journey: journey,
        journey_name: persona["journey_name"] || journey&.full_name,
        spec: persona["spec"]
      }
    end
  end
end
