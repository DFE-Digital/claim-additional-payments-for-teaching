class FeedbackController < BasePublicController
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
      params
        .fetch(:form, {})
        .permit(permitted_keys)
        .merge(journey:)
    )
  end

  def permitted_keys
    form_class_from_slug.new.permitted_keys
  end
end
