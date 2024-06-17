module JourneyConcern
  extend ActiveSupport::Concern

  included do
    helper_method :current_journey_routing_name, :journey, :journey_configuration, :journey_session, :answers, :claim_in_progress?
  end

  def current_journey_routing_name
    params[:journey] || session[:current_journey_routing_name]
  end

  def journey
    Journeys.for_routing_name(current_journey_routing_name)
  end

  def journey_configuration
    journey.configuration
  end

  def journey_session
    @journey_session ||= find_journey_session
  end

  def answers
    journey_session.answers
  end

  def claim_in_progress?
    session[journey_session_key].present?
  end

  def clear_journey_sessions!
    journey_session_keys.each { |key| session.delete(key) }
    @journey_session = nil
    @journey_sessions = []
  end

  private

  def find_journey_session
    journey::Session.find_by(id: session[journey_session_key])
  end

  def journey_session_key
    :"#{current_journey_routing_name}_journeys_session_id"
  end

  def journey_sessions
    @journey_sessions ||= Journeys::JOURNEYS.map do |journey|
      journey::Session.find_by(id: session[:"#{journey::ROUTING_NAME}_journeys_session_id"])
    end.compact
  end

  def other_journey_sessions
    journey_sessions.reject { |js| js.journey == current_journey_routing_name }
  end

  def journey_session_keys
    Journeys::JOURNEYS.map { |journey| :"#{journey::ROUTING_NAME}_journeys_session_id" }
  end
end
