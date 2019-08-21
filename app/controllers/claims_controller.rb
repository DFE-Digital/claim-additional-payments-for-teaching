class ClaimsController < ApplicationController
  before_action :send_unstarted_claiments_to_the_start, only: [:show, :update, :ineligible]
  before_action :check_page_is_in_sequence, only: [:show, :update]

  after_action :clear_claim_session, if: :submission_complete?

  def create
    claim = Claim.create!(eligibility: StudentLoans::Eligibility.new)
    session[:claim_id] = claim.to_param

    redirect_to claim_path("qts-year")
  end

  def show
    search_schools if params[:school_search]
    render claim_page_template
  end

  def update
    if update_current_claim!
      redirect_to claim_path(next_slug)
    else
      show
    end
  end

  def ineligible
  end

  def refresh_session
    head :ok
  end

  private

  def update_current_claim!
    ClaimUpdate.new(current_claim, claim_params, params[:slug]).perform
  end

  def next_slug
    page_sequence.next_slug
  end

  def submission_complete?
    params[:slug] == "confirmation" && current_claim.submitted?
  end

  def search_schools
    @schools = School.search(params[:school_search])
  rescue ArgumentError => e
    raise unless e.message == School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR

    current_claim.errors.add(:school_search, "Search for the school name with a minimum of four characters")
  end

  def claim_params
    params.fetch(:claim, {}).permit(StudentLoans::PermittedParameters.new(current_claim).keys)
  end

  def claim_page_template
    params[:slug].underscore
  end

  def check_page_is_in_sequence
    raise ActionController::RoutingError.new("Not Found") unless page_sequence.in_sequence?(params[:slug])
  end

  def page_sequence
    @page_sequence ||= PageSequence.new(current_claim, params[:slug])
  end
end
