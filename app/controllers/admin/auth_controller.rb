module Admin
  class AuthController < BaseAdminController
    skip_before_action :ensure_authenticated_user

    protect_from_forgery except: :bypass_callback

    def sign_in
    end

    def sign_out
      session.destroy
      redirect_to admin_sign_in_path, notice: "You've been signed out"
    end

    def callback
      dfe_sign_in_user = DfeSignIn::User.admin.from_session(admin_session)

      if dfe_sign_in_user&.has_admin_access?
        dfe_sign_in_user.regenerate_session_token
        dfe_sign_in_user.save

        session[:user_id] = dfe_sign_in_user.id
        session[:token] = dfe_sign_in_user.session_token

        redirect_to session.delete(:requested_admin_path) || admin_root_path
      else
        render "failure", status: :unauthorized
      end
    end

    def failure
    end

    alias_method :bypass_callback, :callback

    private

    def admin_session
      return developer_session if DfESignIn.bypass?

      DfeSignIn::AuthenticatedSession.from_auth_hash(request.env.fetch("omniauth.auth"))
    end

    def developer_session
      DfeSignIn::AuthenticatedSession.new(
        user_id: nil,
        organisation_id: nil,
        organisation_ukprn: nil,
        role_codes: params[:roles]
      )
    end
  end
end
