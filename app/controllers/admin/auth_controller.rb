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
      admin_session = DfeSignIn::AuthenticatedSession.from_auth_hash(request.env.fetch("omniauth.auth"))
      dfe_sign_in_user = DfeSignIn::User.from_session(admin_session)

      if dfe_sign_in_user.has_admin_access?
        dfe_sign_in_user.save

        session[:user_id] = dfe_sign_in_user.id
        session[:organisation_id] = admin_session.organisation_id

        redirect_to session.delete(:requested_admin_path) || admin_root_path
      else
        render "failure", status: :unauthorized
      end
    end

    def failure
    end
  end
end
