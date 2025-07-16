module AutomatedChecks
  module ClaimVerifiers
    class ProviderVerification
      TASK_NAME = "provider_verification".freeze

      def initialize(claim:)
        @claim = claim

        unless claim.policy.further_education_payments?
          raise ArgumentError, "Claim must be an Further Education claim"
        end
      end

      def perform
        return unless claim.eligibility.verified?
        return if task_exists?

        create_task!
      end

      private

      attr_reader :claim

      def task_exists?
        claim.tasks.where(name: TASK_NAME).exists?
      end

      def create_task!
        claim.tasks.create!(
          name: TASK_NAME,
          created_by: created_by,
          manual: false,
          passed: passed?
        )
      end

      def passed?
        verification.fetch("assertions").all? do |assertion|
          assertion.fetch("outcome") == true
        end
      end

      def verification
        @verification ||= claim.eligibility.verification
      end

      def verifier
        verification.fetch("verifier")
      end

      def created_by
        DfeSignIn::User.find_or_create_by!(dfe_sign_in_id: verifier.fetch("dfe_sign_in_uid"), user_type: "provider") do |user|
          user.given_name = verifier.fetch("first_name")
          user.family_name = verifier.fetch("last_name")
          user.email = verifier.fetch("email")
          user.organisation_name = verifier.fetch("dfe_sign_in_organisation_name")
          user.role_codes = verifier.fetch("dfe_sign_in_role_codes")
        end
      end
    end
  end
end
