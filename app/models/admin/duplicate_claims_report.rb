module Admin
  class DuplicateClaimsReport
    include Admin::ClaimsHelper

    attr_reader :academic_year

    def initialize(academic_year)
      @academic_year = academic_year
    end

    def duplicate_claims_report
    end

    def duplicate_claims_csv
      duplicate_claims.includes(:eligibility, :payments, :topups, :notes, decisions: :created_by).map do |claim|
        [
          claim.reference,
          claim.full_name,
          claim.eligibility.try(:teacher_reference_number),
          claim.eligibility.award_amount,
          status(claim),
          claim.latest_decision&.result,
          claim.latest_decision&.created_by&.full_name
        ]
      end
    end

    private

    def duplicate_claims
      Claim.where(id: duplicate_claim_ids)
    end

    def duplicate_claim_ids
      ActiveRecord::Base.connection.execute(
        <<~SQL
          SELECT
            DISTINCT claim_id
          FROM (
            (#{duplicate_claims_on_eligibility})
            UNION
            (#{duplicate_claims_on_claim_details})
          ) AS duplicates
        SQL
      ).values.flatten
    end

    def duplicate_claims_on_claim_details
      <<~SQL
        SELECT
          claims.id AS claim_id,
          other_claims.id AS duplicate_claim_id
        FROM
          claims
        CROSS JOIN
          claims AS other_claims
        WHERE
          claims.academic_year = '#{academic_year}'
        AND
          claims.id != other_claims.id
        AND
          claims.academic_year = other_claims.academic_year
        AND (
          LOWER(claims.email_address) = LOWER(other_claims.email_address)
          OR (
            claims.bank_account_number = other_claims.bank_account_number
            AND claims.bank_sort_code = other_claims.bank_sort_code
          )
          OR (
            LOWER(claims.national_insurance_number) = LOWER(other_claims.national_insurance_number)
          )
          OR (
            LOWER(claims.first_name) = LOWER(other_claims.first_name)
            AND LOWER(claims.surname) = LOWER(other_claims.surname)
            AND claims.date_of_birth = other_claims.date_of_birth
          )
        )
      SQL
    end

    def duplicate_claims_on_eligibility
      claimable_policies.map do |(policy_a, policy_b), attribute_groups|
        joined_eligibilities_query(
          policy_a,
          policy_b,
          attribute_groups
        )
      end.join(" UNION \n")
    end

    # Generates SQL to join two policies' eligibility tables on their
    # eligibility_matching_attributes
    def joined_eligibilities_query(policy_a, policy_b, attribute_groups)
      table_a = policy_a::Eligibility.table_name
      table_b = policy_b::Eligibility.table_name

      table_b_alias = "#{table_b}_2"

      on = attribute_groups.map do |attribute_group|
        "(" + attribute_group.map do |attr|
          "#{table_a}.#{attr} = #{table_b_alias}.#{attr} AND #{table_a}.#{attr} IS NOT NULL AND #{table_a}.#{attr} != ''"
        end.join(" AND ") + ")"
      end.join(" OR ")

      <<~SQL
        SELECT
          claims.id AS claim_id,
          duplicate_claims.id AS duplicate_claim_id
        FROM #{table_a}
        JOIN #{table_b}
          AS #{table_b_alias}
          ON #{on}
        JOIN claims
          ON claims.eligibility_id = #{table_a}.id
        JOIN claims
          AS duplicate_claims
          ON duplicate_claims.eligibility_id = #{table_b_alias}.id
        WHERE #{table_a}.id != #{table_b_alias}.id
        AND claims.academic_year = duplicate_claims.academic_year
        AND claims.academic_year = '#{academic_year}'
      SQL
    end

    # Generates a collection of policy pairs and the attributes they should be
    # compared for duplicates with
    # {
    #   [policy_a, policy_b] => [["teacher_reference_number"]]
    # }
    def claimable_policies
      h = {}
      Policies::POLICIES.each do |policy|
        policy.policies_claimable.each do |claimable_policy|
          attributes_to_match = policy.eligibility_matching_attributes.select do |attr_group|
            claimable_policy.eligibility_matching_attributes.include?(attr_group)
          end

          if attributes_to_match.any?
            h[[policy, claimable_policy].sort_by(&:to_s)] = attributes_to_match
          end
        end
      end
      h
    end
  end
end
