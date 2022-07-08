class SchoolWorkforceCensus < ApplicationRecord
  self.table_name = "school_workforce_censuses"

  SUBJECT_ATTRIBUTES = [
    :subject_1,
    :subject_2,
    :subject_3,
    :subject_4,
    :subject_5,
    :subject_6,
    :subject_7,
    :subject_8,
    :subject_9
  ].freeze

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
    ]
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
    ]
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

  def subjects
    SUBJECT_ATTRIBUTES.map { |attr| send(attr) }.reject(&:blank?)
  end
end
