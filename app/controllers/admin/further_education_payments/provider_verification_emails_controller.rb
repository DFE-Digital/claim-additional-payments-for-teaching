module Admin
  module FurtherEducationPayments
    class ProviderVerificationEmailsController < Admin::BaseAdminController
      before_action :ensure_service_operator

      def create
        claim = Claim.find(params[:claim_id])

        ClaimMailer.further_education_payment_provider_verification_email(claim).deliver_later

        flash[:notice] = "Verification email sent to #{claim.school.name}"

        redirect_back(fallback_location: admin_claim_path(claim))
      end
    end
  end
end
