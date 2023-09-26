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

  LUP_ELIGIBLE_SUBJECTS = {
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
end
