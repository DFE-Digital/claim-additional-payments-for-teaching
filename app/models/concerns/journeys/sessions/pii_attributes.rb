module Journeys
  module Sessions
    module PiiAttributes
      extend ActiveSupport::Concern

      included do
        class_attribute :pii_attributes, default: [], instance_writer: false
      end

      class_methods do
        def attribute(name, type = nil, **options)
          pii_flag = options.delete(:pii)

          if pii_flag.nil?
            raise ArgumentError, "pii indicator for #{name} is required"
          end

          pii_attributes << name if pii_flag

          super
        end
      end

      def attributes_with_pii_redacted
        attributes.map do |key, value|
          if pii_attributes.include?(key.to_sym) && value.present?
            [key, "[PII]"]
          else
            [key, value]
          end
        end.to_h
      end
    end
  end
end
