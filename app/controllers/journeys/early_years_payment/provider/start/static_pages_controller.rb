module Journeys
  module EarlyYearsPayment
    module Provider
      module Start
        class StaticPagesController < BasePublicController
          def guidance
            @journey_open = journey.accessible?(params[:service_access_code])
            render "#{journey.view_path}/guidance"
          end

          def consent_form
            render "#{journey.view_path}/consent_form", layout: "bare"
          end
        end
      end
    end
  end
end
