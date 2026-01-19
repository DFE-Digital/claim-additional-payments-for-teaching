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
      @note = Note.new(note_params)

      if @note.save(context: :create_note)
        redirect_to after_create_path
      elsif task_note?
        redirect_to admin_claim_task_path(@claim, name: task_name), alert: @note.errors.messages[:body].join(", ")
      else
        @notes = @claim.notes.includes(:created_by).order(created_at: :desc)
        @hold_note = Note.new
        render :index
      end
    end

    private

    def note_params
      params.require(:note).permit(:body).merge(
        claim: @claim,
        created_by: admin_user,
        label: task_name
      )
    end

    def task_note?
      params[:task_name].present?
    end

    def task_name
      params[:task_name]
    end

    def after_create_path
      if task_note?
        admin_claim_task_path(@claim, name: task_name)
      else
        admin_claim_notes_url(@claim)
      end
    end
  end
end
