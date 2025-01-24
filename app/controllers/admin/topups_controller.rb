class Admin::TopupsController < Admin::BaseAdminController
  before_action :load_claim
  before_action :load_topup, only: [:remove, :destroy]
  before_action :ensure_service_operator
  before_action :ensure_claim_is_topupable, only: [:new, :create]

  def new
    @form = Admin::CreateTopupForm.new(claim: @claim, created_by: admin_user)
  end

  def create
    @form = Admin::CreateTopupForm.new(claim: @claim, created_by: admin_user, params: topup_params)

    if @form.save
      redirect_to admin_claim_payments_url(@claim), notice: "Claim top up payment created"
    else
      render "new"
    end
  end

  def destroy
    form = Admin::DestroyTopupForm.new(topup: @topup, removed_by: admin_user)

    if form.save
      redirect_to admin_claim_payments_url(@claim), notice: "Top up removed"
    else
      redirect_to admin_claim_payments_url(@claim), notice: form.errors.full_messages.to_sentence
    end
  end

  private

  def load_claim
    @claim = Claim.find(params[:claim_id])
  end

  def ensure_claim_is_topupable
    render "not_topupable" unless @claim.topupable?
  end

  def topup_params
    params.require(:topup).permit(:award_amount)
  end

  def load_topup
    @topup = @claim.topups.find(params[:id])
  end
end
