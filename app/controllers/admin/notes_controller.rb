module Admin
  class NotesController < BaseAdminController
    before_action :ensure_service_operator
    before_action :load_claim
    before_action :set_claim_summary_view

    def index
      @note = Note.new
      @hold_note = Note.new
    end

    def create
      @note = Note.new(note_params)
      if @note.save(context: :create_note)
        redirect_to admin_claim_notes_url(@claim)
      else
        @hold_note = Note.new
        render :index
      end
    end

    private

    def load_claim
      @claim = Claim.find(params[:claim_id])
    end

    def note_params
      params.require(:note).permit(:body).merge(claim: @claim, created_by: admin_user)
    end
  end
end
