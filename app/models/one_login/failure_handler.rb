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
      "#{journey::VIEW_PATH}_auth_failure"
    elsif answers.logged_in_with_onelogin
      "#{journey::VIEW_PATH}_idv_failure"
    end
  end

  private

  def journey
    Journeys::FurtherEducationPayments
  end
end
