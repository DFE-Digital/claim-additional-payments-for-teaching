class RemindersController < BasePublicController
  helper_method :current_reminder
  after_action :reminder_set_email, :clear_sessions, only: [:show]

  def new
    # Skip the OTP process if the current_claim already has email_verified
    # - transfer the email_verified state to the reminder (done in #current_reminder)
    # - jump straight to reminder set
    if current_reminder.email_verified? && current_reminder.save
      redirect_to reminder_path(current_policy_routing_name, "set")
      return
    end

    render first_template_in_sequence
  end

  def create
    current_reminder.attributes = reminder_params

    begin
      one_time_password
    rescue Notifications::Client::BadRequestError => e
      if notify_email_error?(e.message)
        render first_template_in_sequence
        return
      else
        raise
      end
    end

    if current_reminder.save(context: current_slug.to_sym)
      session[:reminder_id] = current_reminder.to_param
      redirect_to reminder_path(current_policy_routing_name, next_slug)
    else
      render first_template_in_sequence
    end
  end

  def show
    render current_template
  end

  def update
    current_reminder.attributes = reminder_params
    one_time_password
    if current_reminder.save(context: current_slug.to_sym)
      redirect_to reminder_path(current_policy_routing_name, next_slug)
    else
      show
    end
  end

  private

  def first_template_in_sequence
    Reminder::SLUGS.first.underscore
  end

  def current_template
    current_slug.underscore
  end

  def next_template
    next_slug.underscore
  end

  def next_slug
    Reminder::SLUGS[current_slug_index + 1]
  end

  def current_slug
    Reminder::SLUGS[current_slug_index]
  end

  def current_slug_index
    Reminder::SLUGS.index(params[:slug]) || 0
  end

  def current_policy_routing_name
    "additional-payments"
  end

  def policy_configuration
    @policy_configuration ||= PolicyConfiguration.for_routing_name(current_policy_routing_name)
  end

  def current_reminder
    @current_reminder ||=
      reminder_from_session ||
      build_reminder_from_claim ||
      default_reminder
  end

  def reminder_from_session
    return unless session.key?(:reminder_id)

    Reminder.find(session[:reminder_id])
  end

  def build_reminder_from_claim
    return unless current_claim

    Reminder.new(
      full_name: current_claim.full_name,
      email_address: current_claim.email_address,
      itt_academic_year: next_academic_year,
      itt_subject: current_claim.eligibility.eligible_itt_subject,
      email_verified: current_claim.email_verified? # allows the OTP to be skipped if already verified
    )
  end

  # Fallback reminder will set reminder date to the next academic year
  def default_reminder
    Reminder.new(itt_academic_year: next_academic_year)
  end

  def next_academic_year
    policy_configuration.current_academic_year + 1
  end

  def current_claim
    return @current_claim if @current_claim
    return unless session.key?(:claim_id) || session.key?(:submitted_claim_id)

    claims = Claim.includes(:eligibility).where(id: (session[:claim_id] || session[:submitted_claim_id]))
    @current_claim = claims.present? ? CurrentClaim.new(claims: claims) : nil
  end

  def reminder_params
    params.require(:reminder).permit(:full_name, :email_address, :one_time_password)
  end

  def one_time_password
    case current_slug
    when "personal-details"
      if current_reminder.valid?(:"personal-details")
        ReminderMailer.email_verification(current_reminder, otp.code).deliver_now
        session[:sent_one_time_password_at] = Time.now
      end
    when "email-verification"
      current_reminder.update(sent_one_time_password_at: session[:sent_one_time_password_at], one_time_password_category: :reminder_email)
    end
  end

  def otp
    @otp ||= OneTimePassword::Generator.new
  end

  def reminder_set_email
    return unless current_slug == "set" && current_reminder.email_verified?

    ReminderMailer.reminder_set(current_reminder).deliver_now
  end

  def clear_sessions
    return unless current_template == "set"

    session.delete(:claim_id)
    session.delete(:reminder_id)
  end

  def notify_email_error?(msg)
    case msg
    when "ValidationError: email_address is a required property"
      current_reminder.add_invalid_email_error("Enter an email address in the correct format, like name@example.com")
      true
    when "BadRequestError: Can’t send to this recipient using a team-only API key"
      current_reminder.add_invalid_email_error("Only authorised email addresses can be used when using a team-only API key")
      true
    else
      false
    end
  end
end
