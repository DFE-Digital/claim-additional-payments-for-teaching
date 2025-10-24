module Admin
  class NotesController < BaseAdminController
    before_action :ensure_service_operator

    def index
      @claim = Claim.find(params[:claim_id])
      @notes = @claim.notes.includes(:created_by).order(created_at: :desc)
      @note = Note.new
      @hold_note = Note.new
    end

    def create
      @claim = Claim.find(params[:claim_id])
      @notes = @claim.notes.includes(:created_by).order(created_at: :desc)
      @note = Note.new(note_params)
      if @note.save(context: :create_note)
        redirect_to admin_claim_notes_url(@claim)
      else
        @hold_note = Note.new
        render :index
      end
    end

    private

    def note_params
      params.require(:note).permit(:body).merge(claim: @claim, created_by: admin_user)
    end
  end
end
