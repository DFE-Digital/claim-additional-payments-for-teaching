module Policies
  module FurtherEducationPayments
    class YearOneAdminTasksPresenter
      include Admin::PresenterMethods

      attr_reader :claim

      def initialize(claim)
        @claim = claim
      end

      def provider_verification
        AdminProviderVerificationTaskPresenter.new(claim)
      end

      def alternative_identity_verification
        AdminAlternativeIdentityVerificationTaskPresenter.new(claim)
      end

      def provider_name
        [verifier.fetch("first_name"), verifier.fetch("last_name")].join(" ").presence || verifier.fetch("email")
      end

      def provider_verification_submitted?
        claim.eligibility.verification.present?
      end

      # FIXME RL - temp stub so the provider verification task can be completed
      def qualifications
        []
      end

      def employment
        [
          ["Current provider", display_school(claim.eligibility.current_school)]
        ]
      end

      def identity_confirmation
        []
      end

      def student_loan_plan
        [
          ["Student loan plan", claim.student_loan_plan&.humanize]
        ]
      end

      def provider_details
        [
          ["Provider name", claim.eligibility.provider_full_name],
          ["Provider email", claim.eligibility.provider_email],
          ["Claimant name", claim.full_name],
          ["Claimant email", claim.email_address]
        ]
      end

      private

      def verifier
        @verifier ||= claim.eligibility.verification.fetch("verifier")
      end
    end
  end
end
