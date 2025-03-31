class Admin::AmendmentsController < Admin::BaseAdminController
  before_action :load_claim
  before_action :ensure_service_operator
  before_action :ensure_claim_is_amendable, only: [:new, :create]

  def index
  end

  def new
    @amendment = @claim.amendments.build
    @form = Admin::AmendmentForm.new(claim: @claim, admin_user:)
    @form.load_data_from_claim
  end

  def create
    @form = Admin::AmendmentForm.new(amendment_params.merge(claim: @claim, admin_user:))

    if @form.valid? && @form.save
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

  def amendment_params
    params
      .require(:amendment)
      .permit(Admin::AmendmentForm.amendable_attributes(claim: @claim, admin_user:))
  end
end
