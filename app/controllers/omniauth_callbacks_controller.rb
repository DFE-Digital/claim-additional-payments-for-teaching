class OmniauthCallbacksController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]

    session[:user_info] = auth.extra.raw_info

    redirect_to claim_path(policy: "additional-payments", slug: "teacher-detail")
  end
end
