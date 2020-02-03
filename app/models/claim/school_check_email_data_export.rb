require "csv"

class Claim
  # Generates CSV data giving the information needed by a service operator to
  # perform the mail merge which they use to send the "school check" emails.
  # These are emails which a service operator sends to schools to verify the
  # eligibility information provided by the claimant.
  #
  # The service operator must give us a list of claim references for which the
  # school check email has already been sent. These claims will be excluded
  # from the output of this class.
  class SchoolCheckEmailDataExport
    attr_reader :comma_separated_claim_references_to_exclude

    def initialize(comma_separated_claim_references_to_exclude)
      @comma_separated_claim_references_to_exclude = comma_separated_claim_references_to_exclude
    end

    def csv_string
      CSV.generate { |csv|
        csv << ["Claim reference", "Policy", "Current school URN", "Current school name", "Claim school URN", "Claim school name", "Claimant name", "Subject"]

        claims.each do |claim|
          csv << [claim.reference,
                  claim.policy.name,
                  claim.eligibility.current_school.urn,
                  claim.eligibility.current_school.name,
                  (claim.eligibility.claim_school.urn if claim.policy.is_a? StudentLoans),
                  (claim.eligibility.claim_school.name if claim.policy.is_a? StudentLoans),
                  claimant_name(claim),
                  subject(claim),
                 ]
        end
      }
    end

    private

    def claims
      Claim.awaiting_checking
        .where.not(reference: claim_references_to_exclude)
        .includes(eligibility: [:current_school])
    end

    def claim_references_to_exclude
      comma_separated_claim_references_to_exclude.split(",")
    end

    def claimant_name(claim)
      [claim.first_name, claim.surname].compact.join(" ")
    end

    def subject(claim)
      claim.policy::SchoolCheckEmailDataExportPresenter.new(claim).subject
    end
  end
end
