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
      if authorised?
        session[:role_codes] = role_codes
        session[:admin_auth] = auth_hash.fetch("info").to_h
        redirect_to admin_path
      else
        render "failure", status: :unauthorized
      end
    end

    def failure
    end

    private

    def role_codes
      @role_codes ||= DfeSignIn::UserAccess.new(
        user_id: user_id,
        organisation_id: organisation_id
      ).role_codes
    end

    def authorised?
      (valid_roles & role_codes).present?
    end

    def valid_roles
      [DFE_SIGN_IN_ADMIN_ROLE_CODE, DFE_SIGN_IN_SUPPORT_ROLE_CODE]
    end

    def auth_hash
      request.env.fetch("omniauth.auth")
    end

    def organisation_id
      auth_hash.dig("extra", "raw_info", "organisation", "id")
    end

    def user_id
      auth_hash["uid"]
    end
  end
end
