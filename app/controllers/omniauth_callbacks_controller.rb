class OmniauthCallbacksController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]
    trn = auth.extra.raw_info.trn
    redirect_to claim_path(policy: "additional-payments", slug: "current-school", trn: trn)
  end
end
