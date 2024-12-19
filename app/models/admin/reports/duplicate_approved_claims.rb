# This file is ignored in the brakeman config, be careful not to interpolate
# any user provided parameters!
module Admin
  module Reports
    class DuplicateApprovedClaims
      HEADERS = [
        "Claim reference",
        "Full name",
        "TRN",
        "Policy",
        "Claim amount",
        "Claim status",
        "Decision date",
        "Decision agent"
      ]

      def initialize(academic_year: AcademicYear.current)
        @academic_year = AcademicYear.wrap(academic_year)
      end

      def filename
        "duplicate_approved_claims.csv"
      end

      def to_csv
        CSV.generate(
          row_sep: "\r\n",
          write_headers: true,
          headers: HEADERS
        ) do |csv|
          rows.each { |row| csv << row }
        end
      end

      private

      class DuplicateClaimRow < Struct.new(:id, :other_claim_id, keyword_init: true); end

      attr_reader :academic_year

      def rows
        scope.map(&ClaimPresenter.method(:new)).map(&:to_a)
      end

      def scope
        Claim.where(id: Set.new(duplicates.map(&:id)))
          .includes(decisions: :created_by)
      end

      def duplicates
        duplicates_by_eligibility + duplicates_by_attributes
      end

      def duplicates_by_eligibility
        ActiveRecord::Base.connection.execute(
          Policies::POLICIES.map do |policy|
            policy_with_claimable_policies(policy)
          end.compact.join("\nUNION\n")
        ).map(&DuplicateClaimRow.method(:new))
      end

      def policy_with_claimable_policies(policy)
        left_table = policy::Eligibility.table_name

        claimable_policies = claimable_policy_mapping(policy)

        return if claimable_policies.empty?

        claimable_policy_mapping(policy).map do |other_policy, matching_attributes|
          right_table = other_policy::Eligibility.table_name
          right_table_alias = "#{right_table}_#{left_table}"

          join_condition = build_join_condition(
            left_table,
            right_table_alias,
            matching_attributes
          )

          <<~SQL
            SELECT claims.id, other_claims.id AS other_claim_id
            FROM #{left_table}
            JOIN #{right_table} #{right_table_alias}
            ON #{left_table}.id != #{right_table_alias}.id
            AND (#{join_condition})
            JOIN claims ON claims.eligibility_id = #{left_table}.id
            JOIN claims other_claims ON other_claims.eligibility_id = #{right_table_alias}.id
            JOIN decisions ON claims.id = decisions.claim_id
            JOIN decisions other_decisions ON other_claims.id = other_decisions.claim_id
            WHERE claims.academic_year = '#{academic_year}'
            AND other_claims.academic_year = '#{academic_year}'
            AND decisions.result = 0
            AND other_decisions.result = 0
          SQL
        end.join("\nUNION\n")
      end

      # [["teacher_reference_number"], ["school_id", "nqt_in_academic_year"]]
      # =>
      # (
      #   (
      #     left_table.teacher_reference_number = right_table.teacher_reference_number
      #     AND left_table.teacher_reference_number IS NOT NULL
      #     AND left_table.teacher_reference_number != ''
      #   )
      # )
      # OR
      # (
      #   (
      #     left_table.school_id = right_table.school_id
      #     AND left_table.school_id IS NOT NULL
      #     AND left_table.school_id != ''
      #   )
      #   AND
      #   (
      #     left_table.nqt_in_academic_year = right_table.nqt_in_academic_year
      #     AND left_table.nqt_in_academic_year IS NOT NULL
      #     AND left_table.nqt_in_academic_year != ''
      #   )
      # )
      def build_join_condition(left_table, right_table, matching_attributes)
        matching_attributes.map do |attr_group|
          "(" + attr_group.map do |attr|
            "(" \
            "#{left_table}.#{attr} = #{right_table}.#{attr} " \
            "AND #{left_table}.#{attr} IS NOT NULL " \
            "AND #{left_table}.#{attr} != ''" \
            ")"
          end.join(" AND ") + ")"
        end.join(" OR ")
      end

      # Return a hash of other claimable policies and the attributes we can
      # use for determining duplicates.
      # "other_policy" => [["attr_1"], ["attr_2", "attr_3"]]
      # If other policy is in the list of claimable policies but shares no
      # matching attributes, we can't compare them, eg EY is in ECP
      # other claimable policies, but EY doesn't have a
      # `teacher_reference_number`.
      def claimable_policy_mapping(policy)
        policy.policies_claimable.map do |other_policy|
          shared_matching_attributes = policy.eligibility_matching_attributes.select do |attribute_group|
            attribute_group.all? do |attr|
              other_policy::Eligibility.column_names.include?(attr)
            end
          end

          [other_policy, shared_matching_attributes]
        end.to_h.reject { |_, matching_attrs| matching_attrs.empty? }
      end

      # building_society_roll_number is no longer used, so is always null
      # we only check the number and sort code when determining duplicates.
      def claim_matching_attributes
        Claim::MatchingAttributeFinder::CLAIM_ATTRIBUTE_GROUPS_TO_MATCH.map do |attr_group|
          attr_group.without("building_society_roll_number")
        end
      end

      def duplicates_by_attributes
        # Limit the claims we're looking at
        current_claims = <<~SQL
          WITH current_claims AS (
            SELECT claims.id, #{claim_matching_attributes.flatten.join(", ")}
            FROM claims
            JOIN decisions ON claims.id = decisions.claim_id
            WHERE claims.academic_year = '#{academic_year}'
            AND decisions.undone = false
            AND decisions.result = 0
          )
        SQL

        # Make sure to have indexes for the columns we're querying!
        filter = claim_matching_attributes.flat_map do |attribute_group|
          join_condition = attribute_group.map do |attr|
            if Claim.column_for_attribute(attr).type == :string
              "LOWER(current_claims.#{attr}) = LOWER(other_claims.#{attr})"
            else
              "current_claims.#{attr} = other_claims.#{attr}"
            end
          end.join(" AND ")

          <<~SQL
            SELECT current_claims.id, other_claims.id AS other_claim_id
            FROM current_claims
            JOIN current_claims other_claims
            ON #{join_condition}
            WHERE current_claims.id != other_claims.id
          SQL
        end.join("\nUNION\n")

        query = current_claims + "\n" + filter

        ActiveRecord::Base.connection.execute(query).map(&DuplicateClaimRow.method(:new))
      end

      class ClaimPresenter
        include Admin::ClaimsHelper

        def initialize(claim)
          @claim = claim
        end

        def to_a
          [
            claim.reference,
            claim.full_name,
            claim.eligibility.try(:teacher_reference_number),
            I18n.t("#{claim.policy.locale_key}.policy_acronym"),
            claim.award_amount,
            status(claim),
            claim.decisions.last.created_at.to_date,
            claim.decisions.last.created_by&.full_name
          ]
        end

        private

        attr_reader :claim
      end
    end
  end
end
