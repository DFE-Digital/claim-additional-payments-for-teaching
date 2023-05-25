require "csv"

class SchoolWorkforceCensusEnhanced < ApplicationRecord
  self.table_name = "school_workforce_censuses_enhanced"

  ECP_ELIGIBLE_SUBJECTS = [
    "Chemistry",
    "Combined/General science",
    "Other Sciences",
    "French",
    "German",
    "Other Modern Languages",
    "Spanish",
    "Other Sciences",
    "Physics",
    "Mathematics"
  ]

  LUP_ELIGIBLE_SUBJECTS = [
    "Chemistry",
    "Combined/General science",
    "Other Sciences",
    "Computing",
    "ICT",
    "Mathematics",
    "Other Sciences",
    "Physics",
  ]

  TSLR_ELIGIBLE_SUBJECTS = [
    "Biology",
    "Computing",
    "ICT",
    "Chemistry",
    "Combined/General science",
    "Other Sciences",
    "French",
    "German",
    "Other Modern Languages",
    "Spanish",
    "Physics",
  ]

  MAP_ELIGIBLE_SUBJECTS = [
    "Combined/General science",
    "Other Sciences",
    "Mathematics",
    "Physics",
  ]

  def self.import_from_csv
    CSV.foreach(Rails.root.join("swc_2021_trn_subject_contract_table.csv")).with_index do |row, i|
      puts "loading row #{i}"
      insert({
        census_year: row[0],
        trn: row[1],
        school_urn: row[2],
        contract_type: row[3],
        fte: row[4],
        full_time: (row[5] == "Full-time"),
        subject: row[6]
      }, unique_by: :swc_unique)
    end
  end

  def match_subject?(policy)
    case policy
    when StudentLoans
      TSLR_ELIGIBLE_SUBJECTS.include? subject
    when MathsAndPhysics
      MAP_ELIGIBLE_SUBJECTS.include? subject
    when LevellingUpPremiumPayments
      LUP_ELIGIBLE_SUBJECTS.include? subject
    when EarlyCareerPayments
      ECP_ELIGIBLE_SUBJECTS.include? subject
    end
  end
end
