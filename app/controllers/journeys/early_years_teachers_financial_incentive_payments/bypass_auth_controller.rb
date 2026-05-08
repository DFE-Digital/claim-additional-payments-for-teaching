module Journeys
  module EarlyYearsTeachersFinancialIncentivePayments
    class BypassAuthController < BasePublicController
      def callback
        persist_callback_to_session

        redirect_to claim_path(current_journey_routing_name, "eligible-qualification-confirmed")
      end

      private

      def form
        @form ||= Debug::TeacherAuth::SignInForm.new(
          journey_session: nil,
          journey: nil,
          params:
        )
      end

      def persist_callback_to_session
        journey_session.answers.assign_attributes(
          teacher_auth_teacher_reference_number: form.trn,
          teacher_auth_email: form.email,
          teacher_auth_verified_name: form.verified_name,
          teacher_auth_verified_date_of_birth: form.verified_date_of_birth,
          teacher_auth_one_login_uid: form.sub,
          trs_data: {},
          trs_data_fetched_at: Time.zone.now,
          has_eligible_qualification: form.has_eligible_qualification
        )
        journey_session.save!
      end
    end
  end
end
