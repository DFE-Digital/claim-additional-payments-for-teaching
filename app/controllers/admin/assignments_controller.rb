class Admin::AssignmentsController < Admin::BaseAdminController
  before_action :ensure_service_operator

  def show
    @claim = Claim.find(params[:claim_id])
    @form = Admin::Claims::AssignmentForm.new(all_params)
  end

  def update
    @claim = Claim.find(params[:claim_id])
    @form = Admin::Claims::AssignmentForm.new(all_params)

    if @form.valid?
      @form.save

      flash[:notice] = @form.flash_message

      redirect_to admin_claim_tasks_path(@claim)
    else
      render :show
    end
  end

  private

  def all_params
    form_params
      .merge(current_admin:, claim: @claim)
  end

  def form_params
    params
      .fetch(:assignment_form, {})
      .permit(
        :assign,
        :colleague_id
      )
  end
end
