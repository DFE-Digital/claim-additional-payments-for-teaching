module ThirdParties
  class AuthorisationFailuresController < BaseController
    def show
      @reason = params[:reason]
    end
  end
end

