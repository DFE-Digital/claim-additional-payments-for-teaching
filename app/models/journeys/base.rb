module Journeys
  module Base
    SHARED_FORMS = {
      "claims" => {
        "sign-in" => SignInForm,
        "sign-in-or-continue" => SignInOrContinueForm,
        "current-school" => CurrentSchoolForm,
        "gender" => GenderForm,
        "personal-details" => PersonalDetailsForm,
        "select-email" => SelectEmailForm,
        "provide-mobile-number" => ProvideMobileNumberForm,
        "select-mobile" => SelectMobileForm,
        "email-address" => EmailAddressForm,
        "email-verification" => EmailVerificationForm,
        "mobile-number" => MobileNumberForm,
        "mobile-verification" => MobileVerificationForm,
        "personal-bank-account" => BankDetailsForm,
        "teacher-reference-number" => TeacherReferenceNumberForm,
        "address" => AddressForm,
        "postcode-search" => PostcodeSearchForm,
        "select-home-address" => SelectHomeAddressForm,
        "check-your-answers" => CheckYourAnswersForm
      }
    }.freeze

    def configuration
      Configuration.find(self::ROUTING_NAME)
    end

    def start_page_url
      slug_sequence.start_page_url
    end

    def slug_sequence
      self::SlugSequence
    end

    def form(journey_session:, params:)
      form = SHARED_FORMS.deep_merge(forms).dig(params[:controller].split("/").last, params[:slug])

      form&.new(journey: self, journey_session:, params:)
    end

    def forms
      defined?(self::FORMS) ? self::FORMS : {}
    end

    def page_sequence_for_claim(journey_session, completed_slugs, current_slug)
      PageSequence.new(
        slug_sequence.new(journey_session),
        completed_slugs,
        current_slug,
        journey_session
      )
    end

    def answers_presenter
      self::AnswersPresenter
    end

    def answers_for_claim(journey_session)
      answers_presenter.new(journey_session)
    end

    def start_with_magic_link?
      defined?(self::START_WITH_MAGIC_LINK) && self::START_WITH_MAGIC_LINK
    end

    def requires_student_loan_details?
      false
    end
  end
end
