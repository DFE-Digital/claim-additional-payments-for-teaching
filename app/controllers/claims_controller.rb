class ClaimsController < ApplicationController
  before_action :send_unstarted_claiments_to_the_start, only: [:show, :update, :ineligible]
  before_action :check_page_is_in_sequence, only: [:show, :update]

  after_action :clear_claim_session, if: :submission_complete?

  def new
    if current_claim.persisted?
      redirect_to claim_path(page_sequence.slugs.first)
    else
      render first_template_in_sequence
    end
  end

  def create
    current_claim.attributes = claim_params
    if current_claim.save(context: page_sequence.slugs.first.to_sym)
      session[:claim_id] = current_claim.to_param
      redirect_to claim_path(next_slug)
    else
      render first_template_in_sequence
    end
  end

  def show
    search_schools if params[:school_search]
    render current_template
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
    ClaimUpdate.new(current_claim, claim_params, page_sequence.current_slug).perform
  end

  helper_method :next_slug
  def next_slug
    page_sequence.next_slug
  end

  def submission_complete?
    page_sequence.current_slug == "confirmation" && current_claim.submitted?
  end

  def search_schools
    schools = ActiveModel::Type::Boolean.new.cast(params[:exclude_closed]) ? School.open : School
    @schools = schools.search(params[:school_search])
  rescue ArgumentError => e
    raise unless e.message == School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR

    current_claim.errors.add(:school_search, "Search for the school name with a minimum of four characters")
  end

  def claim_params
    params.fetch(:claim, {}).permit(StudentLoans::PermittedParameters.new(current_claim).keys)
  end

  def current_template
    page_sequence.current_slug.underscore
  end

  def first_template_in_sequence
    page_sequence.slugs.first.underscore
  end

  def check_page_is_in_sequence
    raise ActionController::RoutingError.new("Not Found") unless page_sequence.in_sequence?(params[:slug])
  end

  def page_sequence
    @page_sequence ||= PageSequence.new(current_claim, params[:slug])
  end
end
