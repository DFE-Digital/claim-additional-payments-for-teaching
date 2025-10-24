module Admin
  class SupportTicketsController < BaseAdminController
    before_action :ensure_service_operator
    before_action :load_claim

    def create
      @support_ticket = @claim.build_support_ticket(support_ticket_params)
      @notes = @claim.notes.includes(:created_by).order(created_at: :desc)
      if @support_ticket.save
        redirect_to admin_claim_notes_url(@claim)
      else
        @note = Note.new
        @hold_note = Note.new
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
