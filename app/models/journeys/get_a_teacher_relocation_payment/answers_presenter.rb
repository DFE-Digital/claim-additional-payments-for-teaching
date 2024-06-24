module Journeys
  module GetATeacherRelocationPayment
    class AnswersPresenter < BaseAnswersPresenter
      include ActionView::Helpers::TranslationHelper

      def eligibility_answers
        [].tap do |a|
          a << application_route
          if answers.trainee?
            a << trainee_details
          else
            a << state_funded_secondary_school
            a << contract_details
          end
          a << start_date_details
          a << subject_details
        end.compact
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

      def trainee_details
        [
          t("get_a_teacher_relocation_payment.forms.trainee_details.question"),
          t("get_a_teacher_relocation_payment.forms.trainee_details.answers.#{answers.state_funded_secondary_school}.answer"),
          "trainee-details"
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
          t("get_a_teacher_relocation_payment.forms.subject.question.#{answers.application_route}"),
          t("get_a_teacher_relocation_payment.forms.subject.answers.#{answers.subject}"),
          "subject"
        ]
      end
    end
  end
end
