module FurtherEducationPayments
  module Providers
    class BaseController < ApplicationController
      include HttpAuthConcern
      include Pagy::Backend

      before_action :authenticate_user!
      before_action :authorize_user!, if: :current_user

      private

      def authenticate_user!
        if current_user.null_user?
          redirect_to new_further_education_payments_providers_session_path
        end
      end

      def authorize_user!
        unless current_user.role_codes.include?(
          Policies::FurtherEducationPayments::CLAIM_VERIFIER_DFE_SIGN_IN_ROLE_CODE
        )
          redirect_to further_education_payments_providers_authorisation_failure_path(
            reason: :incorrect_role
          )
        end
      end

      def claim_scope
        eligibilities = Policies::FurtherEducationPayments::Eligibility
          .joins(:school)
          .merge(
            School
              .where.not(ukprn: nil)
              .where(ukprn: current_user.current_organisation.ukprn)
          )

        Claim
          .by_policy(Policies::FurtherEducationPayments)
          .by_academic_year(
            Journeys::FurtherEducationPayments.configuration.current_academic_year
          )
          .where(eligibility_id: eligibilities.select(:id))
          .where(academic_year: journey_configuration.current_academic_year)
      end

      def current_user
        @current_user ||= DfeSignIn::User
          .not_deleted
          .find_by(id: session[:user_id], session_token: session[:token]) ||
          DfeSignIn::NullUser.new
      end
      helper_method :current_user

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
