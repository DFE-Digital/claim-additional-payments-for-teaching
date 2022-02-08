module TestSeeders
  module Eligibilities
    module StudentLoans
      class CsvImportValidator < BaseCsvImportValidator
        include StudentLoans

        def initialize(records, policy)
          super
        end

        def run
          logger.info "Validating CSV import"
          # iterate over CSV records and find the claim that matches the trn
          # - then find the eligibility for that claim and see if all fields are matched
          # - record the ids of the records that are invalid
          # - full success = 0 errors
          # - partial success = errors because data in CSV file was wrong
          records.each_with_index do |record, idx|
            claim = Claim.find_by(teacher_reference_number: record["Trn"])
            validate_claim_and_eligibility_match_csv_record(claim, record, idx)
          end

          import_status
        end
      end
    end
  end
end
