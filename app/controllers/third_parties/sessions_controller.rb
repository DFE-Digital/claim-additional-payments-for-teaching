module ThirdParties
  class SessionsController < BaseController
    def new
    end

    def callback
      third_party_session = journey::ThirdPartySession.from_omniauth(
        request.env["omniauth.auth"]
      )

      # Ideally we'd have a record in the db but can get away without one
      # so long as we're not storing too much in the session.
      session[journey::ThirdPartySession.session_key] = third_party_session.to_h

      redirect_to session.delete(:after_sign_in_path)
    end
  end
end

