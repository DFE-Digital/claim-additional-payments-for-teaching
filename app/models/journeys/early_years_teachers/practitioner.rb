module Journeys
  module EarlyYearsTeachers
    module Practitioner
      extend Base
      extend self

      ROUTING_NAME = "early-years-teachers-practitioner"
      POLICIES = []

      FORMS = [
        FavouriteColourForm
      ]

      def self.start_page_url
        Rails.application.routes.url_helpers.landing_page_path(ROUTING_NAME)
      end
    end
  end
end
