module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    extend Base
    extend self

    POLICIES = [Policies::EarlyYearsTeachersFinancialIncentivePayments]

    ROUTING_NAME = "early-years-teachers-recognition-payments"

    def forms
      array = []

      array += [
        IneligibleForm,
        NurserySearchForm,
        NurserySelectForm,
        TeachingQualificationConfirmationForm,
        CheckEligibilityForm,
        EligibleTeachingQualificationHeldForm
      ]

      array << if TeacherAuth::Config.instance.bypass?
        Debug::TeacherAuth::SignInForm
      else
        SignInForm
      end

      array += [
        QualificationsCheckForm,
        ContinueClaimForm,
        ClaimCancelledForm,
        UploadEmploymentProofForm,
        ReviewEmploymentProofForm,
        InformationProvidedForm,
        CheckYourAnswersForm,
        ConfirmationForm,
        IneligibleForm
      ]

      array
    end

    def available?
      FeatureFlag.enabled?(:eytfi_journey)
    end

    def requires_student_loan_details?
      true
    end

    def uses_feedback?
      true
    end
  end
end
