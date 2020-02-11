class Admin::ChecksController < Admin::BaseAdminController
  before_action :ensure_service_operator
  before_action :load_claim

  def index
  end

  def show
    render current_check_template
  end

  private

  def load_claim
    @claim = Claim.find(params[:claim_id])
  end

  def current_check_template
    params[:check].parameterize.underscore
  end
end
