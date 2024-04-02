module Journeys
  module Base
    # TODO: move app/forms/*_forms to shared and journey specific folders
    # but needs load_paths sorting
    SHARED_FORMS = {
      "current-school" => CurrentSchoolForm
    }

    def configuration
      Configuration.find(self::ROUTING_NAME)
    end

    def start_page_url
      slug_sequence.start_page_url
    end

    def slug_sequence
      self::SlugSequence
    end

    # TODO: make this work for journey specific forms
    # that list of forms should be defined in the specific journey
    def form(claim:, params:)
      form = SHARED_FORMS[params[:slug]]

      form&.new(journey: self, claim: claim, params: params)
    end
  end
end
