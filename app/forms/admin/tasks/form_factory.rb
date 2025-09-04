module Admin
  module Tasks
    class FormFactory
      def self.form_for_task(name)
        case name.to_s
        when "fe_alternative_verification"
          FeAlternativeVerificationForm
        when "ey_alternative_verification"
          EyAlternativeVerificationForm
        when "payroll_gender"
          PayrollGenderForm
        when "continuous_employment"
          ContinuousEmploymentForm
        when "payroll_details"
          PayrollDetailsForm
        when "matching_details"
          MatchingDetailsForm
        else
          GenericForm
        end
      end
    end
  end
end
