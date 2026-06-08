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
          a << ["Nursery", nursery_with_address, "nursery-search"]
          uploaded_documents.each do |blob|
            a << [
              "Uploaded payslip",
              safe_join([
                govuk_link_to(rails_storage_proxy_path(blob, only_path: true), new_tab: true) {
                  safe_join([
                    content_tag(:span, "Download file ",
                      class: "govuk-visually-hidden"), "#{blob.filename} (opens in new tab)"
                  ])
                },
                ", #{number_to_human_size(blob.byte_size)}"
              ]),
              "review-employment-proof"
            ]
          end
          a << ["Qualification", ey_qualification, nil] if ey_qualification.present?
        end
      end

      def identity_answers
        [].tap do |a|
          a << ["Name", answers.teacher_auth_verified_name, nil]
          a << ["Email address", answers.teacher_auth_email, nil]
          a << ["Home address", address, "postcode-search"]
          a << gender
          a << ["National Insurance number", answers.national_insurance_number, "national-insurance-number"]
        end
      end

      def banking_answers
        [].tap do |a|
          a << ["Name on your account", answers.banking_name, "personal-bank-account"]
          a << ["Sort code", answers.bank_sort_code, "personal-bank-account"]
          a << ["Account number", answers.bank_account_number, "personal-bank-account"]
        end
      end

      private

      def nursery
        Policies::EarlyYearsTeachersFinancialIncentivePayments::EligibleEytfiProvider.find(answers.nursery_id)
      end

      def nursery_with_address
        [
          nursery.name,
          nursery.address_line_1,
          nursery.address_line_2,
          nursery.address_line_3,
          nursery.town,
          nursery.postcode
        ].reject(&:blank?).join(", ")
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

      def ey_qualification
        return if answers.trs_data.blank?

        teacher = Dqt::Teacher.new(answers.trs_data)
        if teacher.has_valid_qts?
          "Qualified Teacher Status (QTS)"
        elsif teacher.has_valid_eyts?
          "Early Years Teacher Status (EYTS)"
        elsif teacher.has_valid_eyps?
          "Early Years Professional Status (EYPS)"
        end
      end
    end
  end
end
