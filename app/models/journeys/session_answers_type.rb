module Journeys
  class SessionAnswersType < ActiveModel::Type::Value
    def type
      :jsonb
    end

    def cast_value(value)
      case value
      when String
        decoded = begin
          ActiveSupport::JSON.decode(value)
        rescue
          nil
        end
        unless decoded.nil?
          decoded_with_allowed_attributes = decoded.slice(*answers_class.attribute_names)
          answers_class.new(decoded_with_allowed_attributes)
        end
      when Hash
        answers_class.new(value)
      when answers_class
        value
      end
    end

    def serialize(value)
      case value
      when Hash
        ActiveSupport::JSON.encode(value)
      when answers_class
        ActiveSupport::JSON.encode(value.attributes)
      else
        super
      end
    end

    def changed_in_place?(raw_old_value, new_value)
      cast_value(raw_old_value) != new_value
    end

    def answers_class
      self.class.module_parent::SessionAnswers
    end
  end
end
