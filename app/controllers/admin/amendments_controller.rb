class Admin::AmendmentsController < Admin::BaseAdminController
  before_action :load_claim
  before_action :ensure_service_operator
  before_action :ensure_claim_is_amendable, only: [:new, :create]

  def index
  end

  def new
    @amendment = @claim.amendments.build
    @form = form_class.new(claim: @claim, admin_user:)
  end

  def create
    @form = form_class.new(
      claim: @claim,
      admin_user: admin_user,
      params: amendment_params
    )

    if @form.valid? && @form.save
      if @form.amendment.bank_details_changed?
        Admin::Claims::HmrcValidationJob.perform_now(@claim)

        flash[:hmrc_bank_verification_claim_id] = @claim.id
      end

      redirect_to admin_claim_tasks_url(@claim), notice: "Claim has been amended successfully"
    else
      render "new"
    end
  end

  private

  def load_claim
    @claim = Claim.find(params[:claim_id])
  end

  def ensure_claim_is_amendable
    unless @claim.amendable?
      render "not_amendable"
    end
  end

  def form_class
    @form_class ||= Admin::AmendmentForm.form_for_claim(@claim)
  end

  def amendment_params
    params
      .require(:amendment)
      .permit(form_class.amendable_attributes(claim: @claim, admin_user:))
  end
end
