module Admin
  module Tasks
    class FeRepeatApplicantCheckForm < GenericForm
      def passed_inclusion_error_message
        "Select yes if applicant check performed and passed"
      end

      def save
        return false if invalid?

        ActiveRecord::Base.transaction do
          task.update(
            passed:,
            created_by: admin_user,
            manual: true
          )

          claim.eligibility.update!(repeat_applicant_check_passed: passed)
        end
      end
    end
  end
end
