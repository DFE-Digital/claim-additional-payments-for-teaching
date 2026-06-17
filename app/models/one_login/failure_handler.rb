class OneLogin::FailureHandler
  attr_reader :message, :origin, :answers

  def initialize(message:, origin:, answers:)
    @message = message
    @origin = origin
    @answers = answers
  end

  def template
    if answers.blank?
      "session_missing_failure"
    elsif !answers.logged_in_with_onelogin
      "#{journey.view_path}_auth_failure"
    elsif answers.logged_in_with_onelogin
      "#{journey.view_path}_idv_failure"
    end
  end

  def notify_sentry!
    Sentry.capture_message "One Login failure"
  end

  private

  def journey
    Journeys::FurtherEducationPayments
  end
end
