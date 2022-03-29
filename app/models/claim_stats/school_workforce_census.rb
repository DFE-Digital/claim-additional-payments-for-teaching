class ClaimStats
  class SchoolWorkforceCensus
    class << self
      def grouped_census_subjects_taught_totals
        Task.census_subjects_taught.group(:claim_verifier_match).count
      end

      def any_match_count
        return 0.0 if Claim.submitted.count.zero?

        any_match_count = grouped_census_subjects_taught_totals["any"].to_i ||= 0
        ((any_match_count / Claim.submitted.count.to_f) * 100).round(1)
      end

      def no_data_census_subjects_taught_count
        return 0.0 if Claim.submitted.count.zero?

        count = grouped_census_subjects_taught_totals[nil].to_i ||= 0
        ((count / Claim.submitted.count.to_f) * 100).round(1)
      end
    end
  end
end
