module TestSeeders
  module Eligibilities
    module EarlyCareerPayments
      class CsvImportValidator < BaseCsvImportValidator
        include EarlyCareerPayments

        def run
          logger.info "Validating CSV import"
          # iterate over CSV records and find the claim that matches the trn
          # - then find the eligibility for that claim and see if all fields are matched
          # - record the ids of the records that are invalid
          # - full success = 0 errors
          # - partial success = errors because data in CSV file was wrong
          # e.g. Mathematical Physics (JAC CODE F320) is actually physics, but entered as Mathematics
          # - results in missing record if in ineligible year (original CSV ITT Cohort Year was 2019-2020)
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
