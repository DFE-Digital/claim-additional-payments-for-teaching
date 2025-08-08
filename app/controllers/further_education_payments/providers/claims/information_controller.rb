module FurtherEducationPayments
  module Providers
    module Claims
      class InformationController < BaseController
        def show
          case params[:information]
          when "progress_saved"
            render "progress_saved"
          else
            redirect_to further_education_payments_providers_claims_path
          end
        end
      end
    end
  end
end
