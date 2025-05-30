module Policies
  module InternationalRelocationPayments
    module EmploymentHistory
      class Type < ActiveModel::Type::Value
        def type
          :jsonb
        end

        def cast_value(value)
          case value
          when String
            deserialize(value)
          when Array
            value.map { cast_element(it) }
          when nil
            []
          else
            raise ArgumentError, "Unsupported value #{value.class}"
          end
        end

        def serialize(value)
          ActiveSupport::JSON.encode(
            value.map { |history| history.attributes }
          )
        end

        def deserialize(value)
          JSON.parse(value || "[]").map { cast_element(it) }
        end

        private

        def cast_element(elem)
          return elem if elem.is_a?(Employment)

          Employment.new(elem.symbolize_keys)
        end
      end
    end
  end
end
