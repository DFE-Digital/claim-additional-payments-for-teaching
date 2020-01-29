class SessionsController < ApplicationController
  include ClaimSessionTimeout
  include AdminSessionTimeout

  def refresh
    clear_claim_session if claim_session_timed_out?
    end_expired_admin_sessions

    head :ok
  end
end
