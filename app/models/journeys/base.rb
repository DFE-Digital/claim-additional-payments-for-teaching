module Journeys
  module Base
    SHARED_FORMS = {
      "sign-in-or-continue" => SignInOrContinueForm,
      "current-school" => CurrentSchoolForm,
      "personal-details" => PersonalDetailsForm,
      "provide-mobile-number" => ProvideMobileNumberForm
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

    def form(claim:, params:)
      form = SHARED_FORMS.merge(forms)[params[:slug]]

      form&.new(journey: self, claim:, params:)
    end

    def forms
      defined?(self::FORMS) ? self::FORMS : {}
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
  end
end
