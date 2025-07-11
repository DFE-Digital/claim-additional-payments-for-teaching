module Journeys
  module GetATeacherRelocationPayment
    class AnswersPresenter < BaseAnswersPresenter
      include ActionView::Helpers::TranslationHelper

      def eligibility_answers
        [].tap do |a|
          a << previous_payment_received
          a << application_route
          a << state_funded_secondary_school
          a << current_school
          a << school_headteacher_name
          a << contract_details
          a << start_date_details
          a << subject_details
          a << changed_workplace_or_new_contract
          a << breaks_in_employment
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

      private

      def show_trn?
        false
      end

      def previous_payment_received
        [
          t("get_a_teacher_relocation_payment.forms.previous_payment_received.question"),
          t("get_a_teacher_relocation_payment.forms.previous_payment_received.answers.#{answers.previous_payment_received}.answer"),
          "previous-payment-received"
        ]
      end

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
          l(answers.start_date),
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

      def changed_workplace_or_new_contract
        [
          t("get_a_teacher_relocation_payment.forms.changed_workplace_or_new_contract.question"),
          t("get_a_teacher_relocation_payment.forms.changed_workplace_or_new_contract.answers.#{answers.changed_workplace_or_new_contract}.answer"),
          "changed-workplace-or-new-contract"
        ]
      end

      def breaks_in_employment
        [
          t("get_a_teacher_relocation_payment.forms.breaks_in_employment.question"),
          t("get_a_teacher_relocation_payment.forms.breaks_in_employment.answers.#{answers.breaks_in_employment}.answer"),
          "breaks-in-employment"
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
          l(answers.date_of_entry),
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

      def current_school
        [
          t("get_a_teacher_relocation_payment.forms.current_school.questions.current_school_search"),
          answers.current_school.name,
          "current-school"
        ]
      end

      def school_headteacher_name
        [
          t("get_a_teacher_relocation_payment.forms.headteacher_details.questions.school_headteacher_name"),
          answers.school_headteacher_name,
          "headteacher-details"
        ]
      end
    end
  end
end
