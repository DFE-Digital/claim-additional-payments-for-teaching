module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    extend Base
    extend self

    POLICIES = [Policies::EarlyYearsTeachersFinancialIncentivePayments]

    def forms
      return @forms if @forms

      array = []

      array << if TeacherAuth::Config.instance.bypass?
        Debug::TeacherAuth::SignInForm
      else
        SignInForm
      end

      array += [
        TrnFoundForm
      ]

      @forms = array
    end

    def available?
      FeatureFlag.enabled?(:eytfi_journey)
    end
  end
end
