module Journeys
  module TeacherStudentLoanReimbursement
    class BypassAuthController < BasePublicController
      def callback
        @form = Debug::TeacherAuth::SignInForm.new(
          journey_session: journey_session,
          journey: Journeys::TeacherStudentLoanReimbursement,
          params: params
        )

        if @form.save
          Debug::TeacherAuth::FetchQualificationsJob.perform_later(
            journey_session
          )

          redirect_to claim_path(
            current_journey_routing_name,
            navigator.next_slug
          )
        else
          render "student_loans/claims/sign_in"
        end
      end

      private

      def navigator
        @navigator ||= Journeys::Navigator.new(
          current_slug: "sign-in",
          journey_session: journey_session,
          params: params,
          session: session
        )
      end
    end
  end
end
