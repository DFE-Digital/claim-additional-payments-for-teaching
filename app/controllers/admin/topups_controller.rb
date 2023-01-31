class Admin::TopupsController < Admin::BaseAdminController
  before_action :load_claim
  before_action :load_topup, only: [:remove, :destroy]
  before_action :ensure_service_operator
  before_action :ensure_claim_is_topupable, only: [:new, :create]

  def new
    @topup = @claim.topups.build
  end

  def create
    @topup = @claim.topups.build(topup_params)

    if @topup.save
      redirect_to admin_claim_payments_url(@claim), notice: "Claim top up payment created"
    else
      render "new"
    end
  end

  def destroy
    if @topup.payrolled?
      redirect_to admin_claim_payments_url(@claim), notice: "Top up cannot be removed if payrolled"
    else
      @topup.destroy
      redirect_to admin_claim_payments_url(@claim), notice: "Top up removed"
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
