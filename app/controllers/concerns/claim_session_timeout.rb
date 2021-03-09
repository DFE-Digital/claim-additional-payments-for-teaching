module ClaimSessionTimeout
  CLAIM_TIMEOUT_LENGTH_IN_MINUTES = 30

  def clear_claim_session
    session.delete(:claim_id)
    @current_claim = nil
  end

  def claim_session_timed_out?
    session.key?(:claim_id) && session[:last_seen_at] < claim_timeout_in_minutes.minutes.ago
  end

  def claim_timeout_in_minutes
    self.class::CLAIM_TIMEOUT_LENGTH_IN_MINUTES
  end
end
