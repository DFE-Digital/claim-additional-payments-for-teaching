module Journeys
  module Base
    def configuration
      Configuration.find(self::ROUTING_NAME)
    end

    def start_page_url
      slug_sequence.start_page_url
    end

    def slug_sequence
      self::SlugSequence
    end

    def page_sequence_for_claim(claim, completed_slugs, current_slug)
      PageSequence.new(claim, slug_sequence.new(claim), completed_slugs, current_slug)
    end
  end
end
