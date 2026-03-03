module Policies
  module TargetedRetentionIncentivePayments
    module Test
      class UserPersona
        FILE = Rails.root.join("spec/personas/targeted_retention_incentive_payments.csv")

        HEADERS = %w[
          claim_year
          expected_result
          notes
          school_name
          supply_teacher
          full_term_contract
          employed_directly_by_school
          subject_to_poor_performance_measures
          itt_year
          more_than_50_of_hours_teaching_eligible_subjects
          teaching_subject
          itt_subject_claimed
          degree_subject
          trainee
          first_name
          last_name
          teacher_reference_number
          date_of_birth
          national_insurance_number
          trs_first_name
          trs_last_name
          trs_date_of_birth
          trs_national_insurance_number
          trs_email_address
          trs_induction_start_date
          trs_induction_completion_date
          trs_induction_status
          trs_qts_award_date
          trs_itt_subject_codes
          trs_itt_subjects
          trs_itt_start_date
          trs_qualification_name
          trs_degree_codes
          trs_degree_names
          trs_active_alert
        ]

        attr_reader :claim_year,
          :expected_result,
          :notes,
          :school_name,
          :supply_teacher,
          :full_term_contract,
          :employed_directly_by_school,
          :subject_to_poor_performance_measures,
          :itt_year,
          :more_than_50_of_hours_teaching_eligible_subjects,
          :teaching_subject,
          :itt_subject_claimed,
          :degree_subject,
          :trainee,
          :first_name,
          :last_name,
          :teacher_reference_number,
          :date_of_birth,
          :national_insurance_number

        attr_accessor :trs_first_name,
          :trs_last_name,
          :trs_date_of_birth,
          :trs_national_insurance_number,
          :trs_email_address,
          :trs_induction_start_date,
          :trs_induction_completion_date,
          :trs_induction_status,
          :trs_qts_award_date,
          :trs_itt_subject_codes,
          :trs_itt_subjects,
          :trs_itt_start_date,
          :trs_qualification_name,
          :trs_degree_codes,
          :trs_degree_names,
          :trs_active_alert

        def initialize(csv_row)
          @claim_year = csv_row["claim_year"]
          @expected_result = csv_row["expected_result"]
          @notes = csv_row["notes"]
          @school_name = csv_row["school_name"]
          @supply_teacher = csv_row["supply_teacher"]
          @full_term_contract = csv_row["full_term_contract"]
          @employed_directly_by_school = csv_row["employed_directly_by_school"]
          @subject_to_poor_performance_measures = csv_row["subject_to_poor_performance_measures"]
          @itt_year = AcademicYear.new(csv_row["itt_year"])
          @more_than_50_of_hours_teaching_eligible_subjects = csv_row["more_than_50_of_hours_teaching_eligible_subjects"]
          @teaching_subject = csv_row["teaching_subject"]
          @itt_subject_claimed = csv_row["itt_subject_claimed"]
          @degree_subject = csv_row["degree_subject"]
          @trainee = csv_row["trainee"]
          @first_name = csv_row["first_name"]
          @last_name = csv_row["last_name"]
          @teacher_reference_number = csv_row["teacher_reference_number"]
          @date_of_birth = csv_row["date_of_birth"]
          @national_insurance_number = csv_row["national_insurance_number"]

          @trs_first_name = csv_row["trs_first_name"]
          @trs_last_name = csv_row["trs_last_name"]
          @trs_date_of_birth = csv_row["trs_date_of_birth"]
          @trs_national_insurance_number = csv_row["trs_national_insurance_number"]
          @trs_email_address = csv_row["trs_email_address"]
          @trs_induction_start_date = csv_row["trs_induction_start_date"]
          @trs_induction_completion_date = csv_row["trs_induction_completion_date"]
          @trs_induction_status = csv_row["trs_induction_status"]
          @trs_qts_award_date = csv_row["trs_qts_award_date"]
          @trs_itt_subject_codes = csv_row["trs_itt_subject_codes"]
          @trs_itt_subjects = csv_row["trs_itt_subjects"]
          @trs_itt_start_date = csv_row["trs_itt_start_date"]
          @trs_qualification_name = csv_row["trs_qualification_name"]
          @trs_degree_codes = csv_row["trs_degree_codes"]
          @trs_degree_names = csv_row["trs_degree_names"]
          @trs_active_alert = csv_row["trs_active_alert"]
        end

        def self.all
          collection = []
          CSV.foreach(FILE, headers: true) { |row| collection << new(row) }
          collection
        end

        def self.eligible
          all.select { |persona| persona.eligible? }
        end

        def self.import!
          SchoolImporter.run
          StriAwardsGenerator.import!
          TeachersPensionsServiceGenerator.import!
          SchoolWorkforceCensusGenerator.import!
        end

        def eligible?
          expected_result == "Eligible"
        end

        def school
          @school ||= School.find_by!(name: school_name)
        end

        # Used for TRS data load
        def qts_date
          AcademicYear.for(Date.today - 3.years).start_of_autumn_term
        end

        # Used for TRS data load
        def route_type
          :undergraduate_itt
        end

        # Used for TRS data load
        def induction_status
          "Pass"
        end

        # Used for TRS data load
        def itt_start_date
          itt_year.start_of_autumn_term
        end

        # Used for TRS data load
        def itt_subject
          Dqt::Matchers::TargetedRetentionIncentivePayments::ELIGIBLE_ITT_SUBJECTS[itt_subject_claimed.downcase.to_sym]&.first ||
            "Random ineligible ITT subject"
        end

        # Used for TRS data load
        def itt_qualification_type
          Dqt::Matchers::General::QUALIFICATION_MATCHING_TYPE[route_type].first
        end

        # Used for TRS data load
        def active_alert?
          false
        end

        def to_csv
          HEADERS.map do |header|
            public_send(header)
          end.join(",")
        end
      end
    end
  end
end
