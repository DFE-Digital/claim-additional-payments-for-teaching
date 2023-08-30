class SchoolWorkforceCensus < ApplicationRecord
  self.table_name = "school_workforce_censuses"

  COMMON_ELIGIBLE_SUBJECTS = {
    chemistry: [
      "Chemistry",
      "Combined/General Science - Chemistry",
      "Applied Science",
      "Other Sciences",
      "Science"
    ],
    foreign_languages: [
      "Arabic",
      "Bengali",
      "Chinese",
      "Danish",
      "French",
      "German",
      "Greek (Classical)",
      "Greek (Modern)",
      "Gujerati",
      "Hebrew (Biblical)",
      "Hebrew (Modern)",
      "Hindi",
      "Italian",
      "Japanese",
      "Latin",
      "Modern Foreign Language",
      "Other Language Subject",
      "Panjabi",
      "Portuguese",
      "Russian",
      "Spanish",
      "Turkish",
      "Urdu"
    ],
    physics: [
      "Combined/General Science - Physics",
      "Physics",
      "Applied Science",
      "Other Sciences",
      "Science"
    ]
  }.freeze

  ECP_ELIGIBLE_SUBJECTS = {
    mathematics: [
      "Economics",
      "Other Mathematical Subject",
      "Statistics",
      "Mathematics / Mathematical Development (Early Years)"
    ],
    none_of_the_above: []
  }.freeze

  LUP_ELIGIBLE_SUBJECTS = {
    chemistry: [
      "Chemistry",
      "Combined/General Science - Chemistry",
      "Applied Science",
      "Other Sciences",
      "Science"
    ],
    computing: [
      "Applied ICT",
      "Computer Science",
      "Information and Communication Technology"
    ],
    mathematics: [
      "Economics",
      "Other Mathematical Subject",
      "Statistics",
      "Mathematics / Mathematical Development (Early Years)"
    ],
    physics: [
      "Combined/General Science - Physics",
      "Physics",
      "Applied Science",
      "Other Sciences",
      "Science"
    ],
    none_of_the_above: []
  }.freeze

  TSLR_ELIGIBLE_SUBJECTS = {
    biology: [
      "Biology / Botany / Zoology / Ecology",
      "Combined/General Science - Biology",
      "Applied Science",
      "Other Sciences",
      "Science"
    ],
    computing: [
      "Applied ICT",
      "Computer Science",
      "Information and Communication Technology"
    ]
  }.freeze
end
