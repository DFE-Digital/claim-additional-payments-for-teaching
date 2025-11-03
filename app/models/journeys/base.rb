module Journeys
  module Base
    SHARED_FORMS = {
      "claims" => {
        "sign-in-or-continue" => TeacherId.bypass? ? SignInOrContinueTestingForm : SignInOrContinueForm,
        "current-school" => CurrentSchoolForm,
        "select-current-school" => SelectCurrentSchoolForm,
        "information-provided" => InformationProvidedForm,
        "gender" => GenderForm,
        "full-name" => FullNameForm,
        "date-of-birth" => DateOfBirthForm,
        "national-insurance-number" => NationalInsuranceNumberForm,
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
      Configuration.find(self.routing_name)
    end

    def start_page_url
      slug_sequence.start_page_url
    end

    def slug_sequence
      self::SlugSequence
    end

    def form(journey_session:, params:, session:)
      form = all_forms.dig(params[:controller].split("/").last, params[:slug])

      form&.new(journey: self, journey_session:, params:, session:)
    end

    def form_class_for_slug(slug:)
      all_forms.dig("claims", slug)
    end

    def slug_for_form(form:)
      all_forms["claims"].invert[form.class]
    end

    def forms
      defined?(self::FORMS) ? self::FORMS : {}
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

    def journey_name
      I18n.t(:journey_name, scope: self::I18N_NAMESPACE)
    end

    def pii_attributes
      SessionAnswers.pii_attributes
    end

    def accessible?(code = nil)
      configuration.open_for_submissions? ||
        ServiceAccessCode.permits_access?(code: code, journey: self)
    end

    def uses_reminders?
      false
    end

    def view_path
      if defined?(self::VIEW_PATH)
        self::VIEW_PATH
      else
        self.name.demodulize.underscore
      end
    end

    def routing_name
      if defined?(self::ROUTING_NAME)
        self::ROUTING_NAME
      else
        self.name.demodulize.underscore.dasherize
      end
    end

    def policies
      self::POLICIES
    end

    def full_name
      [
        I18n.t(:journey_name, scope: self::I18N_NAMESPACE),
        I18n.t(:journey_description, scope: self::I18N_NAMESPACE, default: "")
      ].reject(&:blank?).join(" - ")
    end

    private

    def all_forms
      SHARED_FORMS.deep_merge(forms)
    end
  end
end
