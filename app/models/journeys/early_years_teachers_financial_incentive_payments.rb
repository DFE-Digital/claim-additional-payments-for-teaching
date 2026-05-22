module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    extend Base
    extend self

    POLICIES = [Policies::EarlyYearsTeachersFinancialIncentivePayments]

    def forms
      array = []

      array += [
        IneligibleForm,
        NurserySearchForm,
        NurserySelectForm,
        TeachingQualificationConfirmationForm,
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
        UploadedEmploymentProofForm,
        DeleteEmploymentProofForm,
        UploadEmploymentProofSuccessForm,
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
  end
end
