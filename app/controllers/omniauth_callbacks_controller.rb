class OmniauthCallbacksController < ApplicationController
  include PartOfClaimJourney
  skip_before_action :check_whether_closed_for_submissions
  skip_before_action :send_unstarted_claimants_to_the_start

  def callback
    auth = request.env["omniauth.auth"]

    session[:user_info] = auth.extra.raw_info

    redirect_to claim_path(policy: policy.routing_name, slug: "teacher-detail")
  end

  private

  def policy
    @policy ||= current_claim.policy
  end
end
