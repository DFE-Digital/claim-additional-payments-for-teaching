class ClaimsController < ApplicationController
  def new
  end

  def create
    claim = TslrClaim.create!
    session[:tslr_claim_id] = claim.to_param

    redirect_to qts_year_claim_path
  end

  def update
    current_claim.update_attributes(claim_params)
    redirect_to claim_school_claim_path
  end

  def qts_year
  end

  def claim_school
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
