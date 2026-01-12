module Policies
  module TargetedRetentionIncentivePayments
    module Test
      class UserPersona
        FILE = Rails.root.join("spec/personas/targeted_retention_incentive_payments.csv")

        attr_reader :school_name,
          :teaching_subject,
          :expected_result,
          :first_name,
          :last_name,
          :date_of_birth,
          :national_insurance_number,
          :itt_subject_claimed,
          :itt_year,
          :teacher_reference_number

        def initialize(csv_row)
          @school_name = csv_row["School name"]
          @first_name = csv_row["First name"]
          @last_name = csv_row["Last name"]
          @date_of_birth = csv_row["Date of birth"]
          @national_insurance_number = csv_row["NINO"]
          @itt_subject_claimed = csv_row["ITT subject claimed"]
          @itt_year = AcademicYear.new(csv_row["ITT year"])
          @teacher_reference_number = csv_row["TRN"]
          @teaching_subject = csv_row["Teaching subject"]
          @expected_result = csv_row["Expected result"]
        end

        def self.all
          collection = []
          CSV.foreach(FILE, headers: true) { |row| collection << new(row) }
          collection
        end

        def self.eligible
          all.select { |persona| persona.eligible? }
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
      end
    end
  end
end
