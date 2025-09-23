module FurtherEducationPayments
  module Providers
    class VerifiedClaimsController < BaseController
      def index
        @all_claims = claim_scope.includes(:eligibility)
        @pagy, @claims = pagy(claim_scope)
        @stats = FurtherEducationPayments::Providers::Claims::Stats
          .new(school: current_school)
      end

      def show
        @claim = claim_scope.find(params[:id])
        @answers_presenter =
          FurtherEducationPayments::
          Providers::
          Claims::
          AnswersPresenter.new(claim: @claim)
      end

      private

      def claim_scope
        super
          .where(id: Claim.fe_provider_verified.select(:id))
          .order(:first_name, :surname)
      end
    end
  end
end
