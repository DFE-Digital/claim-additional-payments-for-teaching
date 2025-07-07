module FurtherEducationPayments
  module Providers
    class SessionsController < BaseController
      skip_before_action :authorize_user!, only: [:new]
      skip_before_action :authenticate_user!, only: [:new]

      def new
      end

      def destroy
        reset_session

        redirect_to new_further_education_payments_providers_session_path
      end
    end
  end
end
