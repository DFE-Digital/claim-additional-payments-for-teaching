module ThirdParties
  module Claims
    class VerificationsController < ApplicationController
      include DfE::Analytics::Requests
      include HttpAuthConcern

      before_action :add_view_paths
      before_action :authenticate_user!
      before_action :authorise_user!
      before_action :setup_form

      def show
        # render success page
      end

      def new
        # render form to verify the claim
      end

      def create
        if @form.save
          redirect_to(
            third_parties_claims_verification_path(
              claim_id: claim.id,
              journey: params[:journey]
            )
          )
        else
          render :new
        end
      end

      private

      def authenticate_user!
        return if third_party_session.signed_in?

        session[:after_sign_in_path] = request.path

        redirect_to new_third_parties_session_path(journey: params[:journey])
      end

      def authorise_user!
        return if authorisation.authorised?

        redirect_to third_parties_authorisation_failure_path(
          authorisation.failure_reason,
          journey: params[:journey]
        )
      end

      def authorisation
        @authorisation ||= journey::ThirdPartyAuthorisation.new(
          user: third_party_session,
          record: claim
        )
      end

      def third_party_session
        @third_party_session ||= journey::ThirdPartySession.from_session(
          session[journey::ThirdPartySession.session_key] || {}
        )
      end

      def setup_form
        @form = journey::ThirdPartyVerificationForm.new(
          claim: claim,
          params: params
        )
      end

      def claim
        @claim ||= Claim.find(params[:claim_id])
      end

      def journey
        @journey ||= Journeys.for_routing_name(params[:journey])
      end

      def add_view_paths
        prepend_view_path(Rails.root.join("app", "views", journey::VIEW_PATH))
      end

      def current_journey_routing_name
        journey::ROUTING_NAME
      end

      helper_method :current_journey_routing_name
    end
  end
end

