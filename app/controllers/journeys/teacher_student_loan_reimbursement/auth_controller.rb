module Journeys
  module TeacherStudentLoanReimbursement
    class AuthController < BasePublicController
      def callback
        persist_callback_to_session

        FetchTrsDataJob.perform_later(journey_session)

        redirect_to claim_path(
          current_journey_routing_name,
          "qualifications-check"
        )
      end

      def failure
        Sentry.capture_message "Teacher Auth failure for student loans"
        render :failure, status: :unauthorized
      end

      private

      def current_journey_routing_name
        Journeys::TeacherStudentLoanReimbursement.routing_name
      end

      def persist_callback_to_session
        identity = request.env["omniauth.auth"].extra.raw_info
        name = identity.verified_name
        date_of_birth = Date.parse(identity.verified_date_of_birth)
        now = Time.current

        journey_session.answers.update!(
          teacher_auth_teacher_reference_number: identity.trn,
          teacher_auth_email: identity.email,
          teacher_auth_verified_name: name.join(" "),
          teacher_auth_verified_date_of_birth: date_of_birth,
          teacher_auth_first_name: name.first,
          teacher_auth_last_name: name.last,
          teacher_auth_date_of_birth: date_of_birth,
          teacher_auth_one_login_uid: identity.sub,
          teacher_auth_completed_at: now,
          identity_confirmed_with_onelogin: true,
          onelogin_idv_at: now,
          details_check: true,
          teacher_reference_number: identity.trn,
          first_name: name.first,
          middle_name: name[1...-1].join(" ").presence,
          surname: name.last,
          date_of_birth: date_of_birth,
          qualifications_details_check: nil,
          qts_award_year: nil,
          trs_data_fetched_at: nil,
          national_insurance_number: nil,
          confirm_national_insurance_number: nil
        )
      end
    end
  end
end
