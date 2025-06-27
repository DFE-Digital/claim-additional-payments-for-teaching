module FurtherEducationPayments
  module Providers
    class SessionsController < BaseController
      skip_before_action :authorize_user!, only: [:new]
      skip_before_action :authenticate_user!, only: [:new]

      def new
      end
    end
  end
end

