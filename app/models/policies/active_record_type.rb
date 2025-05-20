module Policies
  class ActiveRecordType < ActiveRecord::Type::Value
    def cast(value)
      case value
      when String
        Policies.from_policy_string(value)
      when *Policies.all
        value
      end
    end

    def serialize(value)
      case value
      when String
        Policies.from_policy_string(value).name
      when *Policies.all
        value.name
      end
    end

    def deserialize(value)
      case value
      when String
        Policies.from_policy_string(value)
      end
    end

    def type
      :policy
    end
  end
end
