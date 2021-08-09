class RemindersController < BasePublicController
  helper_method :current_reminder

  def new
    render :personal_details
  end

  def create
    current_reminder.attributes = reminder_params
    if current_reminder.save(context: :"personal-details")
      session[:reminder_id] = current_reminder.to_param
      redirect_to reminder_path("early-career-payments", current_template)
    else
      render :personal_details
    end
  end

  def show
    render current_template
  end

  private

  def current_policy_routing_name
    "early-career-payments"
  end

  def current_reminder
    @current_reminder ||= reminder_from_session || Reminder.new
  end

  def reminder_from_session
    Reminder.find(session[:reminder_id]) if session.key?(:reminder_id)
  end

  def reminder_params
    params.require(:reminder).permit(:full_name, :email_address, :one_time_password)
  end

  def current_template
    Reminder::SLUGS[current_slug_index + 1].underscore
  end

  def current_slug_index
    Reminder::SLUGS.index(params[:slug]) || 0
  end

  def one_time_password
    case params[:slug]
    when "personal-details"
      ReminderMailer.email_verification(current_reminder.email, otp.code).deliver_now
      session[:sent_one_time_password_at] = Time.now
    when "email-verification"
      current_reminder.update_attributes(sent_one_time_password_at: session[:sent_one_time_password_at])
    end
  end

  def otp
    @otp ||= OneTimePassword::Generator.new
  end
end
