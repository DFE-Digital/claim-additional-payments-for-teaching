module Admin
  class SupportTicketsController < BaseAdminController
    before_action :load_claim

    def create
      @support_ticket = @claim.build_support_ticket(support_ticket_params)
      if @support_ticket.save
        redirect_to admin_claim_notes_url(@claim)
      else
        render "admin/notes/index"
      end
    end

    private

    def load_claim
      @claim = Claim.find(params[:claim_id])
    end

    def support_ticket_params
      params.require(:support_ticket).permit(:url).merge(created_by: admin_user)
    end
  end
end
