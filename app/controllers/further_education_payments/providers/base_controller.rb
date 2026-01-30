module FurtherEducationPayments
  module Providers
    class BaseController < ApplicationController
      include HttpAuthConcern
      include Pagy::Backend

      before_action :check_fe_provider_dashboard_open
      before_action :authenticate_user!
      before_action :authorize_user!, if: :current_user

      private

      def check_fe_provider_dashboard_open
        if FeatureFlag.disabled?("fe_provider_dashboard")
          render "further_education_payments/providers/closed"
        end
      end

      def authenticate_user!
        if current_user.null_user?
          redirect_to new_further_education_payments_providers_session_path
        end
      end

      def authorize_user!
        unless current_user.role_codes.include?(
          Policies::FurtherEducationPayments::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE
        )
          return redirect_to further_education_payments_providers_authorisation_failure_path(
            reason: :incorrect_role
          )
        end

        unless current_provider
          redirect_to further_education_payments_providers_authorisation_failure_path(
            reason: :no_service_access
          )
        end
      end

      def current_user
        @current_user ||= DfeSignIn::User
          .not_deleted
          .find_by(id: session[:user_id], session_token: session[:token]) ||
          DfeSignIn::NullUser.new
      end
      helper_method :current_user

      def current_provider
        @current_provider ||= Policies::FurtherEducationPayments::EligibleFeProvider.find_by(
          ukprn: current_user.current_organisation.ukprn
        )
      end

      # FIXME RL: decide if this is the right approach
      # Required to get application layout to render
      def current_journey_routing_name
        "further-education-payments"
      end
      helper_method :current_journey_routing_name

      class Journey
        def self.view_path
          "further_education_payments/providers"
        end
      end

      def journey
        Journey
      end
      helper_method :journey

      def journey_configuration
        @journey_configuration ||= Journeys::Configuration.find(current_journey_routing_name)
      end
    end
  end
end
