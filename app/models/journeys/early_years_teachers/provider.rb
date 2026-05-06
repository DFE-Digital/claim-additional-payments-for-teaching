module Journeys
  module EarlyYearsTeachers
    module Provider
      extend Base
      extend self

      ROUTING_NAME = "early-years-teachers-provider"
      POLICIES = []

      FORMS = [
        ProviderEmailForm,
        CheckYourEmailForm,
        CheckNurseryDetailsForm,
        UpdateNurseryDetailsForm,
        EmployerPayeReferenceForm,
        OrganisationEmailAddressForm,
        ProvideTeacherDetailsForm,
        PerformanceAndDisciplineForm,
        TeacherNotEligibleForm,
        ManageTeachersForm,
        CheckYourAnswersForm,
        ConfirmationForm
      ]

      def self.start_page_url
        Rails.application.routes.url_helpers.landing_page_path(ROUTING_NAME)
      end
    end
  end
end
