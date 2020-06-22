# Removes personal data from a claim where the claim is
# either rejected and hasn't been updated in over two months, or where the claim
# was scheduled to be paid more than two months ago.
#
# Attributes are set to nil, and personal_data_removed_at is set to the current timestamp.

class Claim
  class PersonalDataScrubber
    PERSONAL_DATA_ATTRIBUTES_TO_DELETE = [
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
      :banking_name
    ]

    TIME_BEFORE_CLAIM_CONSIDERED_OLD = 2.months

    def scrub_completed_claims
      Claim.transaction do
        old_claims_rejected_or_paid.includes(:amendments).each do |claim|
          scrub_amendments_personal_data(claim)
        end

        old_claims_rejected_or_paid.update_all(attribute_values_to_set)
      end
    end

    private

    def attribute_values_to_set
      PERSONAL_DATA_ATTRIBUTES_TO_DELETE.map { |attr| [attr, nil] }.to_h.merge(
        personal_data_removed_at: Time.zone.now
      )
    end

    def old_claims_rejected_or_paid
      Claim.left_outer_joins(payment: [:payroll_run])
        .joins(:decisions)
        .where(personal_data_removed_at: nil)
        .where(
          "(decisions.undone = false AND decisions.result = :rejected AND decisions.created_at < :minimum_time) OR scheduled_payment_date < :minimum_time",
          minimum_time: TIME_BEFORE_CLAIM_CONSIDERED_OLD.ago,
          rejected: Decision.results.fetch(:rejected)
        )
    end

    def scrub_amendments_personal_data(claim)
      claim.amendments.each do |amendment|
        scrub_amendment_personal_data(amendment)
      end
    end

    def scrub_amendment_personal_data(amendment)
      attributes_to_scrub = PERSONAL_DATA_ATTRIBUTES_TO_DELETE.map(&:to_s) & amendment.claim_changes.keys
      personal_data_mask = attributes_to_scrub.to_h { |attribute| [attribute, nil] }
      amendment.claim_changes.merge!(personal_data_mask)

      amendment.personal_data_removed_at = Time.zone.now

      amendment.save!
    end
  end
end
