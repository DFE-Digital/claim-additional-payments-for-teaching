module Policies
  module TargetedRetentionIncentivePayments
    module Test
      class UserPersona
        FILE = Rails.root.join("spec/personas/targeted_retention_incentive_payments.csv")

        attr_reader :school_name

        def initialize(csv_row)
          @school_name = csv_row["School name"]
        end

        def self.all
          collection = []
          CSV.foreach(FILE, headers: true) { |row| collection << new(row) }
          collection
        end
      end
    end
  end
end
