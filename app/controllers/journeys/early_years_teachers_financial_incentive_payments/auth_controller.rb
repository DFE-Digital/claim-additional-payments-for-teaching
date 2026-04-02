module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class AuthController < BasePublicController
      def callback
        persist_callback_to_session

        redirect_to claim_path(current_journey_routing_name, "trn-found")
      end

      private

      def omniauth_hash
        @omniauth_hash ||= request.env["omniauth.auth"]
      end

      def persist_callback_to_session
        journey_session.answers.assign_attributes(
          teacher_auth_teacher_reference_number: omniauth_hash.extra.raw_info.trn,
          teacher_auth_email: omniauth_hash.extra.raw_info.email,
          teacher_auth_verified_name: omniauth_hash.extra.raw_info.verified_name.join(" "),
          teacher_auth_verified_date_of_birth: Date.parse(omniauth_hash.extra.raw_info.verified_date_of_birth),
          teacher_auth_one_login_uid: omniauth_hash.extra.raw_info.sub
        )
        journey_session.save!
      end
    end
  end
end
