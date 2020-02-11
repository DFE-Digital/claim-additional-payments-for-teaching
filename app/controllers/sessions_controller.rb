class SessionsController < BasePublicController
  skip_before_action :end_expired_claim_sessions

  def refresh
    clear_claim_session if claim_session_timed_out?

    head :ok
  end
end
