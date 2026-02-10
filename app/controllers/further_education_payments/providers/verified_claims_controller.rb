module FurtherEducationPayments
  module Providers
    class VerifiedClaimsController < BaseController
      def index
        scope = current_provider.claims.by_academic_year(
          Journeys::FurtherEducationPayments.configuration.current_academic_year
        ).verified.order(:first_name, :surname)
        @all_claims = scope.includes(:eligibility)
        @pagy, @claims = pagy(scope)
        @stats = FurtherEducationPayments::Providers::Claims::Stats
          .new(provider: current_provider)
      end

      def show
        @claim = current_provider.claims.by_academic_year(
          Journeys::FurtherEducationPayments.configuration.current_academic_year
        ).verified.find(params[:id])
        @answers_presenter =
          FurtherEducationPayments::
          Providers::
          Claims::
          AnswersPresenter.new(claim: @claim)

        @claim_presenter =
          FurtherEducationPayments::Providers::Claims::ClaimPresenter
            .new(@claim)
      end
    end
  end
end
