module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class AuthController < BasePublicController
      def callback
        persist_callback_to_session

        if existing_claim_in_window?
          redirect_to claim_path(current_journey_routing_name, "existing-claim")
        else
          ::SchoolTargetedRetentionIncentivePayments::FetchTrsDataJob.perform_later(journey_session:)

          redirect_to claim_path(current_journey_routing_name, "query-teacher-details")
        end
      end

      def failure
        Sentry.capture_message "Teacher Auth failure for STRI"
      end

      private

      def current_journey_routing_name
        Journeys::SchoolTargetedRetentionIncentivePayments.routing_name
      end

      def omniauth_hash
        @omniauth_hash ||= request.env["omniauth.auth"]
      end

      def persist_callback_to_session
        journey_session.answers.update!(
          teacher_auth_teacher_reference_number: omniauth_hash.extra.raw_info.trn,
          teacher_auth_email: omniauth_hash.extra.raw_info.email,
          teacher_auth_verified_name: omniauth_hash.extra.raw_info.verified_name.join(" "),
          teacher_auth_verified_date_of_birth: Date.parse(omniauth_hash.extra.raw_info.verified_date_of_birth),
          teacher_auth_one_login_uid: omniauth_hash.extra.raw_info.sub,
          teacher_auth_completed_at: Time.zone.now,
          identity_confirmed_with_onelogin: true,
          onelogin_idv_at: Time.zone.now
        )
      end

      def existing_claim_in_window?
        OneLoginAccount
          .new(uid: omniauth_hash.extra.raw_info.sub)
          .claims
          .where(policy: Policies::TargetedRetentionIncentivePayments)
          .where(academic_year: journey.configuration.current_academic_year)
          .exists?
      end
    end
  end
end
