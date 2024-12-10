module Journeys
  module EarlyYearsPayment
    module Provider
      module Start
        class StaticPagesController < BasePublicController
          def guidance
            @journey_open = journey.configuration.open_for_submissions?
            render "#{journey::VIEW_PATH}/guidance"
          end
        end
      end
    end
  end
end
