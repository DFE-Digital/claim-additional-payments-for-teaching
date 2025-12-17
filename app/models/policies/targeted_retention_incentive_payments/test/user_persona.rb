module Policies
  module TargetedRetentionIncentivePayments
    module Test
      class UserPersona
        FILE = Rails.root.join("spec/personas/targeted_retention_incentive_payments.csv")

        attr_reader :school_name, :trn, :teaching_subject, :expected_result

        def self.all
          collection = []
          CSV.foreach(FILE, headers: true) { |row| collection << new(row) }
          collection
        end

        def self.eligible
          all.select { |persona| persona.eligible? }
        end

        def initialize(csv_row)
          @school_name = csv_row["School name"]
          @trn = csv_row["TRN"]
          @teaching_subject = csv_row["Teaching subject"]
          @expected_result = csv_row["Expected result"]
        end

        def eligible?
          expected_result == "Eligible"
        end

        def school
          @school ||= School.find_by(name: school_name)
        end
      end
    end
  end
end
