module DataRetention
  class BaseSchedule
    class_attribute :claim_attributes, instance_writer: false
    class_attribute :eligibility_attributes, instance_writer: false
    class_attribute :eligibility_attachments_to_destroy, instance_writer: false, default: {}

    def self.claim_redacted_attributes
      claim_attributes.reject { |k, v| v == :retained }.keys
    end

    def self.eligibility_redacted_attributes
      eligibility_attributes.reject { |k, v| v == :retained }.keys
    end

    def self.apply(claim)
      ChangeSet.new(
        claim: claim,
        retention_schedule: self,
        evaluation_context: EvaluationContext.new(claim)
      )
    end

    def self.claims_to_scrub
      policy_data_retention = module_parent #=> Policies::<PolicyName>::DataRetention
      policy = policy_data_retention.module_parent #=> Policies::<PolicyName> eg tri

      base_scope = Claim
        .after_academic_year(AcademicYear.new(2023)) # Don't try and scrub very old claims
        .before_academic_year(AcademicYear.current)
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

        if default_value.is_a?(Array)
          base_scope.where.not(attr => default_value).where.not(attr => nil)
        else
          empty = if !default_value.nil?
            [nil, default_value]
          end

          base_scope.where.not(attr => empty)
        end
      end.reduce(&:or)

      if eligibility_redacted_attributes.any?
        eligibility_scope = eligibility_redacted_attributes.map(&:to_s).map do |attr|
          default_value = policy::Eligibility.new.send(attr.to_s)

          qualified_attribute = "#{policy::Eligibility.table_name}.#{attr}"

          if default_value.is_a?(Array)
            base_scope.where.not(qualified_attribute => default_value).where.not(qualified_attribute => nil)
          else
            empty = if !default_value.nil?
              [nil, default_value]
            end

            base_scope.where.not(qualified_attribute => empty)
          end
        end.reduce(&:or)

        claim_scope = claim_scope.or(eligibility_scope)
      end

      claim_scope
    end
  end
end
