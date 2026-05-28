module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class Eligibility < ApplicationRecord
      self.table_name = "early_years_teachers_financial_incentive_payments_eligibilities"

      has_one :claim, as: :eligibility, inverse_of: :eligibility
      has_many_attached :employment_proofs

      AMENDABLE_ATTRIBUTES = []

      def policy
        Policies::EarlyYearsTeachersFinancialIncentivePayments
      end

      def eligible_eytfi_provider
        @eligible_eytfi_provider ||= EligibleEytfiProvider
          .where(urn: eligible_eytfi_provider_urn)
          .order(created_at: :desc) # Handle EytfiProviders being backed by file uploads
          .first!
      end

      def ey_qualification
        if dqt_teacher.has_valid_qts?
          "Qualified Teacher Status"
        elsif dqt_teacher.has_valid_eyts?
          "Early Years Teacher Status"
        elsif dqt_teacher.has_valid_eyps?
          "Early Years Professional Status"
        else
          "Unknown QTS"
        end
      end

      private

      def dqt_teacher
        @dqt_teacher ||= Dqt::Teacher.new(trs_data)
      end
    end
  end
end
