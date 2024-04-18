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

    def form(claim:, params:)
      form = all_forms[params[:slug]]
      form&.new(journey: self, claim: claim, params: params)
    end

    # Returns a Hash of slug => class pairs of form classes automatically determined
    def all_forms
      @@all_forms ||= Form.all_shared_forms
        .concat(journey_forms)
        .map { |klass| [klass.slug_name, klass] }
        .to_h
    end

    def page_sequence_for_claim(claim, completed_slugs, current_slug)
      PageSequence.new(claim, slug_sequence.new(claim), completed_slugs, current_slug)
    end

    def answers_presenter
      self::AnswersPresenter
    end

    def answers_for_claim(claim)
      answers_presenter.new(claim)
    end

    private

    def journey_forms
      @@journey_forms ||= constants
        .select { |c| const_get(c).is_a?(Class) }
        .map { |c| const_get(c) }
        .select { |klass| klass < Form }
    end
  end
end
