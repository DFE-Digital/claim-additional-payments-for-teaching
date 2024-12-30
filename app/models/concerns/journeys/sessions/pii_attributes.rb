module Journeys
  module Sessions
    module PiiAttributes
      extend ActiveSupport::Concern

      included do
        class_attribute :pii_attributes, default: [], instance_writer: false
      end

      class_methods do
        def attribute(name, type = nil, **options)
          pii_attributes << name if options.delete(:pii)
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
