module Admin
  module Tasks
    class MatchingDetailsForm < GenericForm
      def passed_inclusion_error_message
        "Select yes if this claim is valid"
      end
    end
  end
end
