class SessionsController < BasePublicController
  skip_before_action :end_expired_claim_sessions

  def refresh # TODO - is this method or controller needed?
    head :ok
  end
end
