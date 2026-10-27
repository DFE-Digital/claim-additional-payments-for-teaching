module Journeys
  module SchoolTargetedRetentionIncentivePayments
    extend Base
    extend self

    ROUTING_NAME = "targeted-retention-incentive-payments".freeze

    POLICIES = [Policies::TargetedRetentionIncentivePayments].freeze
    FORMS = [
      CurrentSchoolForm,
      SelectCurrentSchoolForm,
      IneligibleForm,
      HalfContractedHoursForm,
      SignInForm,
      ExistingClaimForm,
      ExistingClaimsForm,
      QueryTeacherDetailsForm,
      MaybeEligibleForm,
      InformationProvidedForm,
      PersonalBankAccountForm,
      CheckYourAnswersForm,
      ConfirmationForm
    ].freeze

    def forms
      array = [
        CurrentSchoolForm,
        SelectCurrentSchoolForm,
        IneligibleForm,
        HalfContractedHoursForm
      ]

      array << if TeacherAuth::SchoolConfig.instance.bypass?
        Debug::TeacherAuth::School::SignInForm
      else
        SignInForm
      end

      array += [
        ExistingClaimForm,
        ExistingClaimsForm,
        QueryTeacherDetailsForm,
        VerifyNationalInsuranceNumberForm,
        NationalInsuranceNumberForm,
        TeacherDetailsForm,
        MaybeEligibleForm,
        MaybeEligibleForm,
        InformationProvidedForm,
        PersonalBankAccountForm,
        CheckYourAnswersForm,
        ConfirmationForm
      ]

      array
    end

    def available?
      FeatureFlag.enabled?(:new_stri)
    end

    def set_a_reminder?(itt_year)
      false
    end

    def requires_student_loan_details?
      true
    end
  end
end
