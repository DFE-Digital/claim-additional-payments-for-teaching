class RemindersController < BasePublicController
  before_action :create_journey_session_if_no_session

  def show
    @form = form_from_slug

    if @form.set_reminder_from_claim
      redirect_to reminder_path(journey: journey::ROUTING_NAME, slug: "confirmation")
    elsif params[:slug] == "confirmation" && @form.reminder.nil?
      redirect_to journey_session.journey_class.start_page_url
    else
      render view_file
    end
  end

  def update
    @form = form_from_slug

    if @form.valid?
      redirect_to reminder_path(
        journey: journey::ROUTING_NAME,
        slug: navigator.next_slug
      )

      @form.save!
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
    :"#{journey::ROUTING_NAME}_journeys_session_id"
  end

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
      params:,
      session:
    )
  end
end
