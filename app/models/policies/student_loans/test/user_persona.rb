module Policies
  module StudentLoans
    module Test
      class UserPersona
        FILE = Rails.root.join("spec/personas/student_loans.csv")

        attr_reader :school_name,
          :expected_result,
          :first_name,
          :last_name,
          :date_of_birth,
          :national_insurance_number,
          :teacher_reference_number

        def initialize(csv_row)
          @school_name = csv_row["school_name"]
          @first_name = csv_row["first_name"]
          @last_name = csv_row["last_name"]
          @date_of_birth = csv_row["date_of_birth"]
          @national_insurance_number = csv_row["nino"]
          @teacher_reference_number = csv_row["trn"]
          @expected_result = csv_row["expected_result"]
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
          SchoolImporter.import!
        end

        def eligible?
          expected_result == "eligible"
        end

        def school
          @school ||= School.find_by!(name: school_name)
        end
      end
    end
  end
end
