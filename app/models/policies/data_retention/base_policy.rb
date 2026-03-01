module Policies
  module DataRetention
    class BasePolicy
      class_attribute :claim_attributes, instance_writer: false
      class_attribute :eligibility_attributes, instance_writer: false

      def self.claim_redacted_attributes
        claim_attributes.reject { |k, v| v == :retained }.keys
      end

      def self.eligibility_redacted_attributes
        eligibility_attributes.reject { |k, v| v == :retained }.keys
      end

      def self.apply(claim)
        ChangeSet.new(
          claim: claim,
          data_retention_policy: self,
          evaluation_context: EvaluationContext.new(claim)
        )
      end

      def self.claims_to_scrub
        data_retention = module_parent #=> Policies::<PolicyName>::DataRetention
        policy = data_retention.module_parent #=> Policies::<PolicyName> eg tri

        claim_scope = Claim
          .by_academic_year(AcademicYear.previous)
          .joins(
            <<~SQL
              JOIN #{policy::Eligibility.table_name}
              ON #{policy::Eligibility.table_name}.id = claims.eligibility_id
              AND claims.eligibility_type = '#{policy::Eligibility}'
            SQL
          )

        claim_scope = claim_redacted_attributes.map(&:to_s).map do |attr|
          # Can't use `Claim.column_defaults` due to typecasting around array
          # columns
          default_value = Claim.new.send(attr)

          empty = if !default_value.nil?
            [nil, default_value]
          end

          claim_scope.where.not(attr => empty)
        end.reduce(&:or)

        if eligibility_redacted_attributes.any?
          claim_scope = eligibility_redacted_attributes.map(&:to_s).map do |attr|
            default_value = policy::Eligibility.new.send(attr.to_s)

            empty = if !default_value.nil?
              [nil, default_value]
            end

            claim_scope.where.not("#{policy::Eligibility.table_name}.#{attr}" => empty)
          end.reduce(&:or)
        end

        claim_scope
      end
    end
  end
end
