class OmniauthCallbacksController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]

    session[:user_info] = auth.extra.raw_info

    redirect_to claim_path(policy: policy.routing_name, slug: "teacher-detail")
  end

  private

  def claim_id
    @claim_id = session["claim_id"]
  end

  def current_claim
    @current_claim ||= Claim.find_by(id: claim_id)
  end

  def policy
    @policy ||= current_claim.policy
  end
end
