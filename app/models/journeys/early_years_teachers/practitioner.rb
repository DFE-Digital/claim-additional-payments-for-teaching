module Journeys
  module EarlyYearsTeachers
    module Practitioner
      extend Base
      extend self

      ROUTING_NAME = "early-years-teachers-practitioner"
      POLICIES = []

      FORMS = [
        SignInOrContinueForm,
        ConfirmDetailsForm,
        CheckYourAnswersPartOneForm,
        EligibilityConfirmedForm,
        PaymentNotAcceptedForm,
        PaymentOptionsForm,
        CheckYourAnswersForm,
        ConfirmationForm
      ]

      def self.start_page_url
        Rails.application.routes.url_helpers.landing_page_path(ROUTING_NAME)
      end

      def self.answers_presenter
        AnswersPresenter
      end
    end
  end
end
