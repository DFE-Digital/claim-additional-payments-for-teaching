module Admin
  module Tasks
    class FormFactory
      def self.form_for_task(name)
        case name.to_s
        when "payroll_gender"
          PayrollGenderForm
        when "continuous_employment"
          ContinuousEmploymentForm
        else
          GenericForm
        end
      end
    end
  end
end
