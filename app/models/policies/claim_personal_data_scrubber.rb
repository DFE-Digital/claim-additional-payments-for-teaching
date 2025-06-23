# Removes personal data from a claim where the claim is
# either rejected and hasn't been updated in over two months, or where the claim
# was scheduled to be paid more than two months ago.
#
# Attributes are set to nil, and personal_data_removed_at is set to the current timestamp.
#
# Inherit policy specifc data scrubbers from this class
# `app/models/policy/{some_policy}/claim_personal_data_scrubber.rb`

module Policies
  class ClaimPersonalDataScrubber
    def scrub_completed_claims
      old_rejected_claims
        .unscrubbed
        .includes(:amendments, :journey_session, :eligibility).each do |claim|
        Claim::Scrubber.scrub!(claim, personal_data_attributes_to_delete)
      end

      old_paid_claims
        .unscrubbed
        .includes(:amendments, :journey_session, :eligibility).each do |claim|
        Claim::Scrubber.scrub!(claim, personal_data_attributes_to_delete)
      end

      if policy_has_retained_attributes?
        claims_rejected_before(extended_period_end_date).where(
          retained_personal_data_attributes_are_not_null
        ).each do |claim|
          Claim::Scrubber.scrub!(
            claim,
            personal_data_attributes_to_retain_for_extended_period
          )
        end

        claims_paid_before(extended_period_end_date).where(
          retained_personal_data_attributes_are_not_null
        ).each do |claim|
          Claim::Scrubber.scrub!(
            claim,
            personal_data_attributes_to_retain_for_extended_period
          )
        end
      end
    end

    private

    def policy
      self.class.module_parent
    end

    def personal_data_attributes_to_delete
      policy::PERSONAL_DATA_ATTRIBUTES_TO_DELETE
    end

    def policy_has_retained_attributes?
      personal_data_attributes_to_retain_for_extended_period.any?
    end

    def personal_data_attributes_to_retain_for_extended_period
      policy::PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD
    end

    def extended_period_end_date
      policy::EXTENDED_PERIOD_END_DATE.call(start_of_academic_year)
    end

    # If the policy defines an empty array of attributes to retain, return
    # a scope that will be empty.
    def retained_personal_data_attributes_are_not_null
      personal_data_attributes_to_retain_for_extended_period.map do |attr|
        "#{attr} IS NOT NULL"
      end.join(" OR ").presence || "FALSE"
    end

    def claim_scope
      Claim.by_policy(policy)
    end

    def old_rejected_claims
      claims_rejected_before(start_of_academic_year)
    end

    def claims_rejected_before(date)
      claim_scope.rejected.where(
        "decisions.created_at < :minimum_time",
        minimum_time: date
      )
    end

    def old_paid_claims
      claims_paid_before(start_of_academic_year)
    end

    def claims_paid_before(date)
      paid_claims.where(
        "payments.scheduled_payment_date < :minimum_time",
        minimum_time: date
      )
    end

    def paid_claims
      claim_ids_with_payrollable_topups = Topup.payrollable.pluck(:claim_id)
      claim_ids_with_payrolled_topups_without_payment_confirmation = Topup.joins(payment: [:payroll_run]).where(payments: {scheduled_payment_date: nil}).pluck(:claim_id)

      claim_scope.approved.joins(payments: [:payroll_run])
        .where.not(id: claim_ids_with_payrollable_topups + claim_ids_with_payrolled_topups_without_payment_confirmation)
    end

    def start_of_academic_year
      Time.zone.local(current_academic_year.start_year, 9, 1)
    end

    def current_academic_year
      AcademicYear.current
    end
  end
end
