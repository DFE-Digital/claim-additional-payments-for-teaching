module Journeys
  module FurtherEducationPayments
    class ThirdPartyAuthorisation
      def initialize(user:, record:)
        @user = user
        @claim = record
      end

      def authorised?
        failure_reason.nil?
      end

      def failure_reason
        return :no_service_access unless service_access?
        return :organisation_mismatch unless organisation_matches?
        nil
      end

      private

      attr_reader :user, :claim

      def service_access?
        dfe_sign_in_user.has_role?("claim-verifier")
      end

      def organisation_matches?
        # Temp early return until fe claims have a school
        return true

        claim.school.ukprn == dfe_sign_in_user.organisation_ukprn
      end

      def dfe_sign_in_user
        @dfe_sign_in_user ||= DfeSignIn::Api::User.new(
          organisation_id: user.organisation_id,
          organisation_ukprn: user.organisation_ukprn,
          user_id: user.uid
        )
      end
    end
  end
end
