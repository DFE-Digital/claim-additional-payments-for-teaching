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
      :banking_name,
      :hmrc_bank_validation_responses,
      :mobile_number
    ]

    def scrub_completed_claims
      Claim.transaction do
        scrub_claims(old_rejected_claims)
        scrub_claims(old_paid_claims)
      end
    end

    private

    def scrub_claims(claims)
      claims.includes(:amendments).each do |claim|
        scrub_amendments_personal_data(claim)
      end

      claims.update_all(attribute_values_to_set)
    end

    def attribute_values_to_set
      PERSONAL_DATA_ATTRIBUTES_TO_DELETE.map { |attr| [attr, nil] }.to_h.merge(
        personal_data_removed_at: Time.zone.now
      )
    end

    def old_rejected_claims
      Claim.joins(:decisions)
        .where(personal_data_removed_at: nil)
        .where(
          "(decisions.undone = false AND decisions.result = :rejected AND decisions.created_at < :minimum_time)",
          minimum_time: minimum_time,
          rejected: Decision.results.fetch(:rejected)
        )
    end

    def old_paid_claims
      claim_ids_with_payrollable_topups = Topup.payrollable.pluck(:claim_id)
      claim_ids_with_payrolled_topups_without_payment_confirmation = Topup.joins(payment: [:payroll_run]).where(payments: {scheduled_payment_date: nil}).pluck(:claim_id)

      Claim.approved.joins(payments: [:payroll_run])
        .where(personal_data_removed_at: nil)
        .where.not(id: claim_ids_with_payrollable_topups + claim_ids_with_payrolled_topups_without_payment_confirmation)
        .where("payments.scheduled_payment_date < :minimum_time", minimum_time: minimum_time)
    end

    def minimum_time
      Time.zone.local(current_academic_year.start_year, 9, 1)
    end

    def current_academic_year
      AcademicYear.current
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
