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
      :mobile_number,
      :teacher_id_user_info,
      :dqt_teacher_status
    ]

    def scrub_completed_claims
      old_rejected_claims
        .where(personal_data_removed_at: nil)
        .includes(:amendments, :journey_session).each do |claim|
        Claim::Scrubber.scrub!(claim, self.class::PERSONAL_DATA_ATTRIBUTES_TO_DELETE)
      end

      old_paid_claims
        .where(personal_data_removed_at: nil)
        .includes(:amendments, :journey_session).each do |claim|
        Claim::Scrubber.scrub!(claim, self.class::PERSONAL_DATA_ATTRIBUTES_TO_DELETE)
      end
    end

    private

    def policy
      self.class.module_parent
    end

    def claim_scope
      Claim.by_policy(policy)
    end

    def old_rejected_claims
      claims_rejected_before(minimum_time)
    end

    def claims_rejected_before(date)
      rejected_claims.where(
        "decisions.created_at < :minimum_time",
        minimum_time: date
      )
    end

    def rejected_claims
      claim_scope.joins(:decisions)
        .where(
          "(decisions.undone = false AND decisions.result = :rejected)",
          rejected: Decision.results.fetch(:rejected)
        )
    end

    def old_paid_claims
      claims_paid_before(minimum_time)
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

    def minimum_time
      Time.zone.local(current_academic_year.start_year, 9, 1)
    end

    def current_academic_year
      AcademicYear.current
    end
  end
end
