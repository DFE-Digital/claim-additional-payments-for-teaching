module Admin
  module FurtherEducationPayments
    class ProviderVerificationEmailsController < Admin::BaseAdminController
      before_action :ensure_service_operator

      def create
        claim = Claim.find(params[:claim_id])

        FurtherEducationPaymentsMailer
          .with(eligibility: claim.eligibility)
          .provider_verification_overdue_chaser_email
          .deliver_later

        claim.eligibility.update!(
          provider_verification_chase_email_last_sent_at: Time.current
        )

        claim.notes.create!(
          created_by: admin_user,
          label: "fe_provider_verification_v2",
          body: "Verification email sent to #{claim.school.name}"
        )

        flash[:notice] = "Verification email sent to #{claim.school.name}"

        redirect_back(fallback_location: admin_claim_path(claim))
      end
    end
  end
end
