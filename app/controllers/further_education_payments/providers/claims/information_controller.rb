module FurtherEducationPayments
  module Providers
    module Claims
      class InformationController < BaseController
        def show
          @claim = claim_scope.find(params[:claim_id])

          case params[:information]
          when "progress_saved"
            render "progress_saved"
          when "claim_rejected"
            render "claim_rejected"
          else
            redirect_to further_education_payments_providers_claims_path
          end
        end
      end
    end
  end
end
