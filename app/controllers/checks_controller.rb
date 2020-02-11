class Admin::ChecksController < Admin::BaseAdminController
  before_action :ensure_service_operator
  before_action :load_claim

  def index
  end

  private

  def load_claim
    @claim = Claim.find(params[:claim_id])
  end
end
