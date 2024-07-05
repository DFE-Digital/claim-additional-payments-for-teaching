module Policies
  module InternationalRelocationPayments
    class ClaimPersonalDataScrubber < Policies::ClaimPersonalDataScrubber
      PERSONAL_DATA_ATTRIBUTES_TO_DELETE = [
        :date_of_birth,
        :address_line_1,
        :address_line_2,
        :address_line_3,
        :address_line_4,
        :postcode,
        :payroll_gender,
        :bank_sort_code,
        :bank_account_number,
        :building_society_roll_number,
        :banking_name,
        :hmrc_bank_validation_responses,
        :mobile_number,
        :teacher_id_user_info,
        :dqt_teacher_status
      ]

      PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD = [
        :first_name,
        :middle_name,
        :surname,
        :national_insurance_number
      ]

      ANY_NON_NULL_EXTENDED_PERIOD_ATTRIBUTES =
        PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD.map do |attr|
          "#{attr} IS NOT NULL"
        end.join(" OR ")

      def scrub_completed_claims
        super

        claims_rejected_before(extended_period_end_date).where(
          ANY_NON_NULL_EXTENDED_PERIOD_ATTRIBUTES
        ).each do |claim|
          Claim::Scrubber.scrub!(
            claim,
            PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD
          )
        end

        claims_paid_before(extended_period_end_date).where(
          ANY_NON_NULL_EXTENDED_PERIOD_ATTRIBUTES
        ).each do |claim|
          Claim::Scrubber.scrub!(
            claim,
            PERSONAL_DATA_ATTRIBUTES_TO_RETAIN_FOR_EXTENDED_PERIOD
          )
        end
      end

      def extended_period_end_date
        minimum_time - 2.years
      end
    end
  end
end
