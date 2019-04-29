class ClaimsController < ApplicationController
  def new
  end

  def create
    claim = TslrClaim.create!
    session[:tslr_claim_id] = claim.to_param

    redirect_to claim_path(:qts_year)
  end

  def show
    render params[:slug]
  end

  def update
    current_claim.update_attributes(claim_params)
    redirect_to claim_path(:claim_school)
  end

  private

  def claim_params
    params.require(:tslr_claim).permit(:qts_award_year)
  end

  def current_claim
    @current_claim ||= TslrClaim.find(session[:tslr_claim_id])
  end
  helper_method :current_claim
end
