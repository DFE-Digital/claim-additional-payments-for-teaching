module Policies
  module FurtherEducationPayments
    class AdminAlternativeIdentityVerificationTaskPresenter
      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      def submitted?
        claim.eligibility.claimant_identity_verified_at.present?
      end

      # Does an admin need to review the alternative identity details?
      def admin_check_required?
        task.nil?
      end

      def task
        @task ||= @claim.tasks.find_by(name: "alternative_identity_verification")
      end
    end
  end
end
