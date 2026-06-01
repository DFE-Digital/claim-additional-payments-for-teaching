class FeedbackController < BasePublicController
  before_action :create_journey_session_if_no_session

  def show
    @form = form_from_slug

    render view_file
  end

  def update
    @form = form_from_slug

    if @form.save
      redirect_to feedback_path(
        journey: journey.routing_name,
        slug: navigator.next_slug
      )
    else
      render view_file
    end
  end

  private

  def create_journey_session_if_no_session
    if session[journey_session_key].blank?
      create_journey_session!
    end
  end

  def create_journey_session!
    journey_session = journey::SessionForm.create!(params)

    session[journey_session_key] = journey_session.id

    journey_session
  end

  def journey_session_key
    :"#{journey.routing_name}_journeys_session_id"
  end

  def view_file
    params[:slug].underscore
  end

  def navigator
    @navigator ||= Journeys::Feedbacks::SlugSequence::Navigator.new(
      current_slug: params[:slug]
    )
  end
  helper_method :navigator

  def form_class_from_slug
    case params[:slug]
    when "details"
      Feedbacks::DetailsForm
    when "confirmation"
      Feedbacks::ConfirmationForm
    else
      raise "form not found"
    end
  end

  def form_from_slug
    form_class_from_slug.new(
      journey_session:,
      journey:,
      params:,
      session:
    )
  end
end
