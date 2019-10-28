class Admin::ClaimsController < Admin::BaseAdminController
  before_action :ensure_service_operator

  def index
    @claims = Claim.includes(:check, eligibility: [:claim_school, :current_school]).awaiting_checking.order(:submitted_at)
  end

  def show
    @claim = Claim.find(params[:id])
    @check = @claim.check || Check.new
    @claim_ids_with_matching_attributes = Claim::MatchingAttributeFinder.new(@claim).claim_ids_with_matching_attributes
  end

  def search
    return unless params[:reference].present?

    claim = Claim.find_by(reference: params[:reference])

    if claim
      redirect_to(admin_claim_url(claim))
    else
      flash.now[:notice] = "Cannot find a claim with reference \"#{params[:reference]}\""
    end
  end
end
