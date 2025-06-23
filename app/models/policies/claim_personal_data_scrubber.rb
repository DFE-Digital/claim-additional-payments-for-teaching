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
        scrub_retained_claims
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

    def scrub_retained_claims
      # The eligibility attributes and claim attributes are defined in the same
      # constant so we need to separate them to avoid undefined attribute
      # errors.
      eligibility_attributes = policy::Eligibility.attribute_names.select do |attr|
        personal_data_attributes_to_retain_for_extended_period.include?(attr.to_sym)
      end

      claim_attributes = Claim.attribute_names.select do |attr|
        personal_data_attributes_to_retain_for_extended_period.include?(attr.to_sym)
      end

      # Find the claims from before the extended period end date
      old_claims = Claim.where(
        id: claims_rejected_before(extended_period_end_date)
      ).or(
        Claim.where(id: claims_paid_before(extended_period_end_date))
      )

      # Generate the filter on eligibility attributes
      eligibilities_with_unscrubbed_pii = eligibility_attributes.map do |attr|
        policy::Eligibility.where.not(attr => nil)
      end.reduce(:or)

      # Generate the filter on claim attributes
      claims_with_unscrubbed_pii = claim_attributes.map do |attr|
        Claim.where.not(attr => nil)
      end.reduce(:or)

      policy::Eligibility
        .joins(:claim)
        .merge(old_claims)
        .merge(eligibilities_with_unscrubbed_pii)
        .merge(claims_with_unscrubbed_pii)
        .includes(claim: [:amendments, :journey_session])
        .each do |eligibility|
          Claim::Scrubber.scrub!(
            eligibility.claim,
            policy::PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD
          )
        end
    end

    def start_of_academic_year
      Time.zone.local(current_academic_year.start_year, 9, 1)
    end

    def current_academic_year
      AcademicYear.current
    end
  end
end
