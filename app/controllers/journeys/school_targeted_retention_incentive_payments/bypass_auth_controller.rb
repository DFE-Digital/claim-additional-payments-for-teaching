module Journeys
  module SchoolTargetedRetentionIncentivePayments
    class BypassAuthController < BasePublicController
      def callback
        persist_callback_to_session

        Debug::StriBypassJob
          .set(wait: 5.seconds)
          .perform_later(
            journey_session:,
            has_national_insurance_number: form.has_national_insurance_number,
            national_insurance_number: form.national_insurance_number
          )

        redirect_to claim_path(current_journey_routing_name, "query-teacher-details")
      end

      private

      def current_journey_routing_name
        Journeys::SchoolTargetedRetentionIncentivePayments.routing_name
      end

      def form
        @form ||= Debug::TeacherAuth::School::SignInForm.new(
          journey_session: nil,
          journey: nil,
          params:
        )
      end

      def persist_callback_to_session
        journey_session.answers.update!(
          teacher_auth_teacher_reference_number: form.trn,
          teacher_auth_email: form.email,
          teacher_auth_verified_name: form.verified_name,
          teacher_auth_verified_date_of_birth: form.verified_date_of_birth,
          teacher_auth_one_login_uid: form.sub,
          teacher_auth_completed_at: Time.zone.now,
          identity_confirmed_with_onelogin: true,
          onelogin_idv_at: Time.zone.now
        )
      end
    end
  end
end
