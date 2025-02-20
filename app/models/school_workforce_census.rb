class SchoolWorkforceCensus < ApplicationRecord
  self.table_name = "school_workforce_censuses"

  COMMON_ELIGIBLE_SUBJECTS = {
    chemistry: [
      "Chemistry",
      "Combined/General science",
      "Other Sciences"
    ],
    foreign_languages: [
      "Spanish",
      "French",
      "German",
      "Other Modern Languages"
    ],
    physics: [
      "Combined/General science",
      "Physics",
      "Other Sciences"
    ]
  }.freeze

  ECP_ELIGIBLE_SUBJECTS = {
    mathematics: [
      "Mathematics",
      "Business / Economics"
    ],
    none_of_the_above: []
  }.freeze

  TARGETED_RETENTION_INCENTIVE_ELIGIBLE_SUBJECTS = {
    chemistry: [
      "Chemistry",
      "Combined/General science",
      "Other Sciences"
    ],
    computing: [
      "ICT",
      "Computing"
    ],
    mathematics: [
      "Mathematics",
      "Business / Economics"
    ],
    physics: [
      "Combined/General science",
      "Physics",
      "Other Sciences"
    ],
    none_of_the_above: []
  }.freeze

  TSLR_ELIGIBLE_SUBJECTS = {
    biology: [
      "Biology",
      "Combined/General science"
    ],
    computing: [
      "ICT",
      "Computing"
    ]
  }.freeze

  class << self
    def grouped_census_subjects_taught_totals
      Task.census_subjects_taught.group(:claim_verifier_match).count
    end

    def any_match_count
      return 0.0 if Claim.count.zero?

      any_match_count = grouped_census_subjects_taught_totals["any"].to_i ||= 0
      ((any_match_count / Claim.count.to_f) * 100).round(1)
    end

    def no_data_census_subjects_taught_count
      return 0.0 if Claim.count.zero?

      count = grouped_census_subjects_taught_totals[nil].to_i ||= 0
      ((count / Claim.count.to_f) * 100).round(1)
    end
  end
end
