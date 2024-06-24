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
    end
  end
end
