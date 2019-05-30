module Admin
  class AuthController < BaseAdminController
    skip_before_action :ensure_authenticated_user

    def sign_in
    end

    def sign_out
      session.destroy
      redirect_to root_path, notice: "You've been signed out"
    end

    def callback
      session[:login] = auth_hash.fetch("info").to_h
      redirect_to admin_path
    end

    def failure
    end

    private

    def auth_hash
      request.env.fetch("omniauth.auth")
    end
  end
end
