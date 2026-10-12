module Policies
  module EarlyYearsTeachersFinancialIncentivePayments
    class AdminClaimPresenter
      include ActionView::Helpers::SanitizeHelper

      def initialize(claim)
        @claim = claim
      end

      def personal_details
        [
          teacher_reference_number,
          full_name,
          date_of_birth,
          national_insurance_number,
          address,
          email_address,
          banking_name,
          bank_account_number,
          bank_sort_code
        ]
      end

      private

      def teacher_reference_number
        [
          I18n.t("admin.teacher_reference_number"),
          claim.eligibility.teacher_reference_number.presence || "Not provided"
        ]
      end

      def full_name
        ["Full name", Admin::ClaimsHelper.personal_data(claim, :full_name)]
      end

      def date_of_birth
        [
          "Date of birth",
          Admin::ClaimsHelper.personal_data(claim, :date_of_birth) { |date| I18n.l(date) }
        ]
      end

      def national_insurance_number
        [
          I18n.t("admin.national_insurance_number"),
          Admin::ClaimsHelper.personal_data(claim, :national_insurance_number)
        ]
      end

      def address
        [
          "Address",
          Admin::ClaimsHelper.personal_data(claim, :address, "<br>") { |address| sanitize(address.html_safe, tags: %w[br]) }
        ]
      end

      def email_address
        [
          I18n.t(
            "#{claim.policy.locale_key}.admin.email_address",
            default: :"admin.email_address"
          ),
          claim.email_address
        ]
      end

      def banking_name
        [
          "Banking name",
          Admin::ClaimsHelper.personal_data(claim, :banking_name)
        ]
      end

      def bank_account_number
        [
          "Bank account number",
          Admin::ClaimsHelper.personal_data(claim, :bank_account_number)
        ]
      end

      def bank_sort_code
        [
          "Bank sort code",
          Admin::ClaimsHelper.personal_data(claim, :bank_sort_code)
        ]
      end

      attr_reader :claim
    end
  end
end
