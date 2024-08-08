module ThirdParties
  module Claims
    class VerificationsController < BaseController
      include ThirdPartyAuthorised

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

      def setup_form
        @form = journey::ThirdPartyVerificationForm.new(
          claim: claim,
          params: params
        )
      end

      def claim
        @claim ||= Claim.find(params[:claim_id])
      end
    end
  end
end

