class ClaimsController < BasePublicController
  include PartOfClaimJourney

  skip_before_action :send_unstarted_claiments_to_the_start, only: [:new, :create, :timeout]
  before_action :check_page_is_in_sequence, only: [:show, :update]

  def new
    clear_claim_session
    render first_template_in_sequence
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
    current_claim.attributes = claim_params
    current_claim.reset_dependent_answers
    current_claim.eligibility.reset_dependent_answers

    if current_claim.save(context: page_sequence.current_slug.to_sym)
      redirect_to claim_path(next_slug)
    else
      show
    end
  end

  def timeout
  end

  private

  helper_method :next_slug
  def next_slug
    page_sequence.next_slug
  end

  def search_schools
    schools = ActiveModel::Type::Boolean.new.cast(params[:exclude_closed]) ? School.open : School
    @schools = schools.search(params[:school_search])
  rescue ArgumentError => e
    raise unless e.message == School::SEARCH_NOT_ENOUGH_CHARACTERS_ERROR

    current_claim.errors.add(:school_search, "Search for the school name with a minimum of four characters")
  end

  def claim_params
    params.fetch(:claim, {}).permit(Claim::PermittedParameters.new(current_claim).keys)
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
    @page_sequence ||= PageSequence.new(current_claim, claim_slug_sequence, params[:slug])
  end

  def claim_slug_sequence
    current_claim.policy::SlugSequence.new(current_claim)
  end
end
