module Policies
  module DataRetention
    class BasePolicy
      class_attribute :claim_attributes, instance_writer: false
      class_attribute :eligibility_attributes, instance_writer: false

      def self.apply(claim)
        ChangeSet.new(
          claim: claim,
          data_retention_policy: self,
          evaluation_context: EvaluationContext.new(claim)
        )
      end
    end
  end
end
