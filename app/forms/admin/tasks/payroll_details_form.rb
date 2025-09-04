module Admin
  module Tasks
    class PayrollDetailsForm < GenericForm
      def passed_inclusion_error_message
        "Select yes if you have checked the bank account details"
      end
    end
  end
end
