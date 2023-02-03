module AutomatedChecks
  module ClaimVerifiers
    class PayrollDetails
      def initialize(claim:, admin_user: nil)
        self.admin_user = admin_user
        self.claim = claim
      end

      def perform
        return if claim.reload.tasks.any? { |task| task.name == "payroll_details" }
        return unless claim.must_manually_validate_bank_details?

        task = claim.tasks.build(name: "payroll_details",
                                 claim_verifier_match: :none,
                                 passed: nil,
                                 manual: true,
                                 created_by: admin_user)

        task.save!(context: :claim_verifier)
        task
      end

      private

      attr_accessor :admin_user, :claim
    end
  end
end
