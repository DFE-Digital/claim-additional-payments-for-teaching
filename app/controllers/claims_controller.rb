class ClaimsController < ApplicationController
  before_action :send_unstarted_claiments_to_the_start, only: [:show, :update, :ineligible]

  def new
  end

  def create
    claim = TslrClaim.create!
    session[:tslr_claim_id] = claim.to_param

    redirect_to claim_path("qts-year")
  end

  def show
    perform_non_js_school_search if params[:school_search]
    render claim_page_template
  end

  def update
    current_claim.attributes = claim_params
    if current_claim.save(context: params[:slug].to_sym)
      redirect_to claim_path(next_slug)
    else
      show
    end
  end

  def ineligible
  end

  private

  def next_slug
    current_slug_index = current_claim.page_sequence.index(params[:slug])
    current_claim.page_sequence[current_slug_index + 1]
  end

  def perform_non_js_school_search
    if params[:school_search].length > 3
      @schools = School.search(params[:school_search])
    else
      current_claim.errors.add(:base, "Search for the school name with a minimum of four characters")
    end
  end

  def claim_params
    params.require(:tslr_claim).permit(:qts_award_year, :claim_school_id, :employment_status, :current_school_id)
  end

  def claim_page_template
    params[:slug].underscore
  end

  def current_claim
    @current_claim ||= TslrClaim.find(session[:tslr_claim_id]) if session.key?(:tslr_claim_id)
  end
  helper_method :current_claim

  def send_unstarted_claiments_to_the_start
    redirect_to root_url unless current_claim.present?
  end
end
