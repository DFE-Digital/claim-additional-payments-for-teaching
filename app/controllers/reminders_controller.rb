class RemindersController < BasePublicController
  def show
    @form = form_from_slug

    render view_file
  end

  def update
    @form = form_from_slug

    if @form.valid?
      redirect_to independent_reminder_path(
        journey: journey::ROUTING_NAME,
        slug: navigator.next_slug
      )

      @form.save!
    else
      render view_file
    end
  end

  private

  def view_file
    params[:slug].underscore
  end

  def navigator
    @navigator ||= Journeys::Reminders::SlugSequence::Navigator.new(
      current_slug: params[:slug]
    )
  end
  helper_method :navigator

  def form_class_from_slug
    case params[:slug]
    when "personal-details"
      Reminders::PersonalDetailsForm
    when "email-verification"
      Reminders::EmailVerificationForm
    when "confirmation"
      Reminders::ConfirmationForm
    else
      raise "form not found"
    end
  end

  def form_from_slug
    form_class_from_slug.new(
      journey_session:,
      journey:,
      params:
    )
  end
end
