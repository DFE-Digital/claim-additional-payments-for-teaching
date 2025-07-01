module FurtherEducationPayments
  module Providers
    class AuthorisationFailuresController < BaseController
      skip_before_action :authorize_user!, only: [:show]
      skip_before_action :authenticate_user!, only: [:show]

      def show
        @reason = params.fetch(:reason) { raise ActiveRecord::RecordNotFound }
      end
    end
  end
end
