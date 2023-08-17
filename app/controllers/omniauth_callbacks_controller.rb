class OmniauthCallbacksController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]
    trn = auth.extra.raw_info.trn

    redirect_params = {
      policy: "additional-payments",
      slug: "current-school"
    }

    redirect_params[:trn] = trn if trn

    redirect_to claim_path(redirect_params)
  end
end
