class OmniauthCallbacksController < ApplicationController
  def callback
    auth = request.env["omniauth.auth"]

    session[:user_info] = auth.extra.raw_info

    redirect_to teacher_detail_path(policy: "additional-payments")
  end
end
