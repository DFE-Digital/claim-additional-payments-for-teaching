module ClaimSessionTimeout # TODO: rename this class - SessionManager?
  def clear_claim_session
    session.delete(:slugs)
    clear_journey_sessions!
  end
end
