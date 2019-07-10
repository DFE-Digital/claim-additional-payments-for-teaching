class ApplicationController < ActionController::Base
  http_basic_authenticate_with(
    name: ENV["BASIC_AUTH_USERNAME"],
    password: ENV["BASIC_AUTH_PASSWORD"],
    if: -> { ENV.key?("BASIC_AUTH_USERNAME") },
  )

  helper_method :signed_in?, :govuk_verify_enabled?, :current_claim

  private

  def send_unstarted_claiments_to_the_start
    redirect_to root_url unless current_claim.present?
  end

  def signed_in?
    session.key?(:login)
  end

  def govuk_verify_enabled?
    ENV["GOVUK_VERIFY_ENABLED"]
  end

  def current_claim
    @current_claim ||= TslrClaim.find(session[:tslr_claim_id]) if session.key?(:tslr_claim_id)
  end

  def update_last_seen_at
    session[:last_seen_at] = Time.zone.now
  end
end
