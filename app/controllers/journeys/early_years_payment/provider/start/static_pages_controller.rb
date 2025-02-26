module Journeys
  module EarlyYearsPayment
    module Provider
      module Start
        class StaticPagesController < BasePublicController
          def guidance
            @journey_open = journey.accessible?(params[:service_access_code])
            render "#{journey::VIEW_PATH}/guidance"
          end
        end
      end
    end
  end
end
