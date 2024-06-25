module Journeys
  module GetATeacherRelocationPayment
    class AnswersPresenter < BaseAnswersPresenter
      include ActionView::Helpers::TranslationHelper

      def eligibility_answers
        [].tap do |a|
          a << application_route
          a << state_funded_secondary_school
          a << contract_details
          a << start_date_details
          a << subject_details
          a << visa_details
          a << entry_date
        end.compact
      end

      def identity_answers
        super.tap do |a|
          a << nationality
          a << passport_number
        end
      end

      def employment_answers
        [].tap do |a|
          a << school_headteacher_name
          a << school_name
          a << school_address_line_1
          a << school_address_line_2 if answers.school_address_line_2.present?
          a << school_city
          a << school_postcode
        end
      end

      private

      def application_route
        [
          t("get_a_teacher_relocation_payment.forms.application_route.question"),
          t("get_a_teacher_relocation_payment.forms.application_route.answers.#{answers.application_route}.answer"),
          "application-route"
        ]
      end

      def state_funded_secondary_school
        [
          t("get_a_teacher_relocation_payment.forms.state_funded_secondary_school.question"),
          t("get_a_teacher_relocation_payment.forms.state_funded_secondary_school.answers.#{answers.state_funded_secondary_school}.answer"),
          "state-funded-secondary-school"
        ]
      end

      def contract_details
        [
          t("get_a_teacher_relocation_payment.forms.contract_details.question"),
          t("get_a_teacher_relocation_payment.forms.contract_details.answers.#{answers.one_year}.answer"),
          "contract-details"
        ]
      end

      def start_date_details
        [
          t("get_a_teacher_relocation_payment.forms.start_date.question"),
          answers.start_date.strftime("%d-%m-%Y"),
          "start-date"
        ]
      end

      def subject_details
        [
          t("get_a_teacher_relocation_payment.forms.subject.question"),
          t("get_a_teacher_relocation_payment.forms.subject.answers.#{answers.subject}"),
          "subject"
        ]
      end

      def visa_details
        [
          t("get_a_teacher_relocation_payment.forms.visa.question"),
          answers.visa_type,
          "visa"
        ]
      end

      def entry_date
        [
          t("get_a_teacher_relocation_payment.forms.entry_date.question"),
          answers.date_of_entry.strftime("%d-%m-%Y"),
          "entry-date"
        ]
      end

      def nationality
        [
          t("get_a_teacher_relocation_payment.forms.nationality.question"),
          answers.nationality,
          "nationality"
        ]
      end

      def passport_number
        [
          t("get_a_teacher_relocation_payment.forms.passport_number.question"),
          answers.passport_number,
          "passport-number"
        ]
      end

      def school_headteacher_name
        [
          t("get_a_teacher_relocation_payment.forms.employment_details.questions.school_headteacher_name"),
          answers.school_headteacher_name,
          "employment-details"
        ]
      end

      def school_name
        [
          t("get_a_teacher_relocation_payment.forms.employment_details.questions.school_name"),
          answers.school_name,
          "employment-details"
        ]
      end

      def school_address_line_1
        [
          t("get_a_teacher_relocation_payment.forms.employment_details.questions.school_address_line_1"),
          answers.school_address_line_1,
          "employment-details"
        ]
      end

      def school_address_line_2
        [
          t("get_a_teacher_relocation_payment.forms.employment_details.questions.school_address_line_2"),
          answers.school_address_line_2,
          "employment-details"
        ]
      end

      def school_city
        [
          t("get_a_teacher_relocation_payment.forms.employment_details.questions.school_city"),
          answers.school_city,
          "employment-details"
        ]
      end

      def school_postcode
        [
          t("get_a_teacher_relocation_payment.forms.employment_details.questions.school_postcode"),
          answers.school_postcode,
          "employment-details"
        ]
      end
    end
  end
end
