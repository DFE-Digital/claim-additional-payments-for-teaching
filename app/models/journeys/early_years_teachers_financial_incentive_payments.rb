module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    extend Base
    extend self

    POLICIES = [Policies::EarlyYearsTeachersFinancialIncentivePayments]

    def forms
      array = []

      array += [
        NurserySearchForm,
        TeachingQualificationConfirmationForm,
        EligibleTeachingQualificationHeldForm
      ]

      array << if TeacherAuth::Config.instance.bypass?
        Debug::TeacherAuth::SignInForm
      else
        SignInForm
      end

      array += [
        TrnFoundForm
      ]

      array
    end

    def available?
      FeatureFlag.enabled?(:eytfi_journey)
    end
  end
end
