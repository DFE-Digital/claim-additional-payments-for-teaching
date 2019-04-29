class ClaimsController < ApplicationController
  before_action :send_unstarted_claiments_to_the_start, only: [:show, :update]

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
    @current_claim ||= TslrClaim.find(session[:tslr_claim_id]) if session.key?(:tslr_claim_id)
  end
  helper_method :current_claim

  def send_unstarted_claiments_to_the_start
    redirect_to root_url unless current_claim.present?
  end
end
