module Policies
  module FurtherEducationPayments
    class AdminAlternativeIdentityVerificationTaskPresenter
      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      def submitted?
        claim.eligibility.claimant_identity_verified_at.present? && task.present?
      end

      # Does an admin need to review the alternative identity details?
      def admin_check_required?
        # The claim verifier leaves the task passed state as nil if there isn't
        # a match on all provided details.
        task.passed.nil?
      end

      def task
        @task ||= @claim.tasks.find_by(name: "alternative_identity_verification")
      end
    end
  end
end
