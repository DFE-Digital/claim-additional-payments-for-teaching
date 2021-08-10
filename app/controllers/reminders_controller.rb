class RemindersController < BasePublicController
  helper_method :current_reminder
  # before_action :check_page_is_in_sequence, only: [:show, :update]

  def new
    render first_template_in_sequence
  end

  def create
    current_reminder.attributes = reminder_params
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

  # def check_page_is_in_sequence
  #   unless Reminder::SLUGS.include?(current_slug)
  #     raise ActionController::RoutingError.new("Not Found")
  #   end
  # end

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

  def one_time_password
    case params[:slug]
    when "personal-details"
      ReminderMailer.email_verification(current_reminder, otp.code).deliver_now
      session[:sent_one_time_password_at] = Time.now
    when "email-verification"
      current_reminder.update_attributes(sent_one_time_password_at: session[:sent_one_time_password_at])
    end
  end

  def otp
    @otp ||= OneTimePassword::Generator.new
  end
end
