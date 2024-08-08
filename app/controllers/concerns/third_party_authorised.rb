# Expects a journey two define two classes
# `SomeJourney::ThirdPartySession`
#    This class needs to implement a class method `.from_session`
#    which will be passed the contents of the controller session,
#    a `to_h` instance method which returns a hash of what to store in the
#    session, and a `signed_in?` instance method which returns a boolean.
#
# `SomeJourney::ThirdPartyAuthorisation`
#    This class is passed `SomeJourney::ThirdPartySession` and the current
#    record to authorised.
#    It should implement an instance method `authorised?` which returns a
#    boolean and `failure_reason` which returns the reason for authorisation
#    failure.
#
#    The including controller needs to implement a `record_to_authorise` method
#    The return value from this method will be passed to the
#    `ThirdPartyAuthorisation` class
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
        record: record_to_authorise
      )
    end
  end
end

