# Removes personally identifiable information from a claim where the claim is
# either rejected and hasn't been updated in over two months, or where the claim
# was scheduled to be paid more than two months ago.
#
# Attributes are set to nil, and pii_removed_at is set to the current timestamp.

class Claim
  class PiiScrubber
    PII_ATTRIBUTES_TO_DELETE = [
      :first_name,
      :middle_name,
      :surname,
      :date_of_birth,
      :address_line_1,
      :address_line_2,
      :address_line_3,
      :address_line_4,
      :postcode,
      :payroll_gender,
      :national_insurance_number,
      :bank_sort_code,
      :bank_account_number,
      :building_society_roll_number,
    ]

    TIME_BEFORE_CLAIM_CONSIDERED_OLD = 2.months

    def scrub_completed_claims
      old_claims_rejected_or_paid.update_all(attribute_values_to_set)
    end

    private

    def attribute_values_to_set
      PII_ATTRIBUTES_TO_DELETE.map { |attr| [attr, nil] }.to_h.merge(
        pii_removed_at: Time.zone.now
      )
    end

    def old_claims_rejected_or_paid
      Claim.left_outer_joins(payment: [:payroll_run])
        .joins(:decision)
        .where(pii_removed_at: nil)
        .where(
          "(decisions.result = :rejected AND decisions.created_at < :minimum_time) OR scheduled_payment_date < :minimum_time",
          minimum_time: TIME_BEFORE_CLAIM_CONSIDERED_OLD.ago,
          rejected: Decision.results.fetch(:rejected)
        )
    end
  end
end
