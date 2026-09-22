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
      QueryTeacherDetailsForm,
      HelloForm,
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
        QueryTeacherDetailsForm,
        VerifyNationalInsuranceNumberForm,
        NationalInsuranceNumberForm,
        TeacherDetailsForm,
        HelloForm,
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
  end
end
