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

        def subject_taught_mismatch(data, eligibility, record)
          # as we don't have mathematics we randomly assign any :mathematics result to
          # either :computing_taught or :biology_taught
          # so this is the matcher for that
          return if %i[computing_taught biology_taught].include?(eligibility.subjects_taught.first)
          return if eligibility.subjects_taught.first == :languages_taught && find_eligible_itt_subject(record["Subject Code"]) == :foreign_languages
          # now match on others e.g. :physics_taught with :physics
          return if eligibility.subjects_taught.first.to_s.split("_").first == find_eligible_itt_subject(record["Subject Code"]).to_s

          data[:eligible_itt_subject] = {
            claim: eligibility.subjects_taught.first,
            csv: find_eligible_itt_subject(record["Subject Code"])
          }
        end
      end
    end
  end
end
