module ThirdPartyAuthorised
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :authorise_user!

    def authenticate_user!
      return if third_party_session.signed_in?

      session[:after_sign_in_path] = request.path

      redirect_to new_third_parties_session_path(journey: params[:journey])
    end

    def authorise_user!
      return if authorisation.authorised?

      redirect_to third_parties_authorisation_failure_path(
        authorisation.failure_reason,
        journey: params[:journey]
      )
    end

    def authorisation
      @authorisation ||= journey::ThirdPartyAuthorisation.new(
        user: third_party_session,
        record: claim
      )
    end
  end
end

