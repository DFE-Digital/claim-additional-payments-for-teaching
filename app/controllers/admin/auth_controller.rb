module Admin
  class AuthController < BaseAdminController
    skip_before_action :ensure_authenticated_user

    def sign_in
    end

    def sign_out
      session.destroy
      redirect_to admin_root_path, notice: "You've been signed out"
    end

    def callback
      admin_session = AdminSession.from_auth_hash(request.env.fetch("omniauth.auth"))

      if admin_session.has_admin_access?
        dfe_sign_in_user = DfeSignIn::User.find_or_create_by(dfe_sign_in_id: admin_session.user_id)

        session[:user_id] = dfe_sign_in_user.id
        session[:organisation_id] = admin_session.organisation_id
        session[:role_codes] = admin_session.role_codes

        redirect_to session.delete(:requested_admin_path) || admin_root_path
      else
        render "failure", status: :unauthorized
      end
    end

    def failure
    end
  end
end
