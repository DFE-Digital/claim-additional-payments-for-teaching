class TestDataController < ApplicationController
  layout "test_data"

  PERSONA_FILES = {
    "student_loans_personas" => {
      label: "Student Loans",
      path: "spec/personas/student_loans.csv"
    },
    "stri_personas" => {
      label: "Schools Targeted Retentions Incentive",
      path: "spec/personas/targeted_retention_incentive_payments.csv"
    }
  }.freeze

  GENERATED_FILES = {
    "trs_data" => {
      label: "TRS Data",
      generator: -> { Policies::TargetedRetentionIncentivePayments::Test::TrsDataGenerator.to_csv.to_s }
    },
    "school_workforce_census" => {
      label: "School Workforce Census",
      generator: -> { Policies::TargetedRetentionIncentivePayments::Test::SchoolWorkforceCensusGenerator.to_csv.to_s }
    },
    "stri_awards" => {
      label: "STRI Awards",
      generator: -> { Policies::TargetedRetentionIncentivePayments::Test::StriAwardsGenerator.to_csv.to_s }
    },
    "teachers_pensions_service" => {
      label: "Teachers Pensions Service",
      generator: -> { Policies::TargetedRetentionIncentivePayments::Test::TeachersPensionsServiceGenerator.to_csv.to_s }
    }
  }.freeze

  def index
    @persona_files = PERSONA_FILES
    @generated_files = GENERATED_FILES
  end

  def download
    file_key = params[:file_key]

    if PERSONA_FILES.key?(file_key)
      path = Rails.root.join(PERSONA_FILES[file_key][:path])
      send_file path, type: "text/csv", filename: "#{file_key}.csv"
    elsif GENERATED_FILES.key?(file_key)
      csv_data = GENERATED_FILES[file_key][:generator].call
      send_data csv_data, type: "text/csv", filename: "#{file_key}.csv"
    else
      head :not_found
    end
  end
end
