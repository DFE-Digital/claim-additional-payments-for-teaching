class OneLoginAccount
  attr_reader :uid

  def initialize(uid:)
    @uid = uid
  end

  def journey_sessions(journey:, academic_year: nil)
    academic_year ||= journey.configuration.current_academic_year

    journey::Session
      .where("answers -> 'onelogin_uid' ? :uid", uid:)
      .where("answers #>> '{academic_year, start_year}' = :start_year", start_year: academic_year.start_year)
      .where("answers #>> '{academic_year, end_year}' = :end_year", end_year: academic_year.end_year)
      .order(updated_at: :asc)
  end

  # ignore sessions that are ineligible
  def resumable_journey_sessions(journey:, academic_year: nil)
    academic_year ||= journey.configuration.current_academic_year

    sessions = journey_sessions(journey:, academic_year:).to_a
    sessions.reject! do |session|
      journey.policies.all? do |policy|
        policy::PolicyEligibilityChecker.new(answers: session.answers).ineligible?
      end
    end
    sessions
  end

  def claims
    raise NotImplementedError
  end
end
