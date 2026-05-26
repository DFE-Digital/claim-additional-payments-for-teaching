module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class AnswersPresenter < BaseAnswersPresenter
      include ActionView::Helpers::TranslationHelper
      include Rails.application.routes.url_helpers
      include ActionView::Helpers::UrlHelper
      include ActionView::Helpers::NumberHelper
      include GovukVisuallyHiddenHelper
      include GovukLinkHelper

      def nursery_answers
        [].tap do |a|
          a << ["Nursery selected", nursery.name, "nursery-search"]
        end
      end

      def identity_answers
        [].tap do |a|
          a << ["Home address", address, "address"]
          a << gender
          a << ["National Insurance number", answers.national_insurance_number, "national-insurance-number"]
        end
      end

      def banking_answers
        [].tap do |a|
          a << ["Name on bank account", answers.banking_name, "personal-bank-account"]
          a << ["Bank sort code", answers.bank_sort_code, "personal-bank-account"]
          a << ["Bank account number", answers.bank_account_number, "personal-bank-account"]
        end
      end

      def upload_answers
        # Should only be ONE
        uploaded_documents.map do |blob|
          [
            "Payslip",
            "#{govuk_link_to(blob.filename.to_s, rails_storage_proxy_path(blob, only_path: true), new_tab: true)}, #{number_to_human_size(blob.byte_size)}",
            "review-employment-proof"
          ]
        end
      end

      private

      def nursery
        Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider.find(answers.nursery_id)
      end

      def address
        [
          answers.address_line_1,
          answers.address_line_2,
          answers.address_line_3,
          answers.address_line_4,
          answers.postcode
        ].reject(&:blank?).join(", ")
      end

      def gender
        [
          "Gender",
          t("answers.payroll_gender.#{answers.payroll_gender}"),
          "gender"
        ]
      end

      def uploaded_documents
        confirmed_ids = answers.confirmed_employment_proof_blob_ids
        ActiveStorage::Blob.where(id: confirmed_ids).order(created_at: :asc)
      end
    end
  end
end
