module Journeys
  module GetATeacherRelocationPayment
    class AnswersPresenter < BaseAnswersPresenter
      include ActionView::Helpers::TranslationHelper

      def eligibility_answers
        [].tap do |a|
          a << application_route
          a << if answers.trainee?
            trainee_details
          else
            state_funded_secondary_school
          end
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
    end
  end
end
