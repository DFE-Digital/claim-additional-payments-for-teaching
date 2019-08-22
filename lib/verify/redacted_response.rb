module Verify
  # Used to report a response from Verify without revealing any Personally
  # Identifiable Information by replacing any string "values" with the "X"
  # character. For example:
  #
  #   Verify::RedactedResponse.new({"value" => "Secret"}).parameters
  #   => {"value" => "XXXXXX"}
  #
  class RedactedResponse
    KEYS_TO_REDACT = %w[value postCode].freeze

    attr_reader :parameters

    def initialize(parameters)
      @parameters = redact_values(parameters.deep_dup)
    end

    private

    def redact_values(input)
      if input.is_a?(String)
        redact_string(input)
      else
        input.tap do |hash_to_redact|
          hash_to_redact.each do |key, value|
            if value.is_a?(Hash)
              hash_to_redact[key] = redact_values(value)
            elsif value.is_a?(Array)
              hash_to_redact[key].each_with_index { |nested_value, nested_key| hash_to_redact[key][nested_key] = redact_values(nested_value) }
            elsif value.is_a?(String) && KEYS_TO_REDACT.include?(key)
              hash_to_redact[key] = redact_string(value)
            end
          end
        end
      end
    end

    def redact_string(string)
      "X" * string.length
    end
  end
end
