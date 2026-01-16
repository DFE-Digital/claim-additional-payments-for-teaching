module Journeys
  module Base
    def configuration
      Configuration.find(routing_name)
    end

    def start_page_url
      slug_sequence.start_page_url
    end

    def slug_sequence
      self::SlugSequence
    end

    def form(journey_session:, params:, session:)
      form_class = form_class_for_slug(slug: params[:slug])

      form_class&.new(journey: self, journey_session:, params:, session:)
    end

    def slug_for_form(form:)
      all_forms_mapping.invert[form.class]
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
      I18n.t(:journey_name, scope: i18n_namespace)
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
        name.gsub(/^Journeys::/, "").gsub("::", "/").underscore
      end
    end

    def routing_name
      if defined?(self::ROUTING_NAME)
        self::ROUTING_NAME
      else
        name.demodulize.underscore.dasherize
      end
    end

    def i18n_namespace
      if defined?(self::I18N_NAMESPACE)
        self::I18N_NAMESPACE
      else
        name.gsub("Journeys::", "").gsub("::", "_").underscore
      end
    end

    def policies
      self::POLICIES
    end

    def full_name
      [
        I18n.t(:journey_name, scope: i18n_namespace),
        I18n.t(:journey_description, scope: i18n_namespace, default: "")
      ].reject(&:blank?).join(" - ")
    end

    def form_class_for_slug(slug:)
      all_forms_mapping[slug]
    end

    private

    def all_forms_mapping
      shared_forms_mapping.merge(forms_mapping)
    end

    def shared_forms
      array = []

      array << if TeacherId::Config.instance.bypass?
        Debug::SignInOrContinueForm
      else
        SignInOrContinueForm
      end

      array += [
        CurrentSchoolForm,
        SelectCurrentSchoolForm,
        InformationProvidedForm,
        GenderForm,
        FullNameForm,
        DateOfBirthForm,
        NationalInsuranceNumberForm,
        PersonalDetailsForm,
        SelectEmailForm,
        ProvideMobileNumberForm,
        SelectMobileForm,
        EmailAddressForm,
        EmailVerificationForm,
        MobileNumberForm,
        MobileVerificationForm,
        PersonalBankAccountForm,
        TeacherReferenceNumberForm,
        AddressForm,
        PostcodeSearchForm,
        SelectHomeAddressForm,
        CheckYourAnswersForm
      ]

      array
    end

    def shared_forms_mapping
      mapping = {}

      shared_forms.map do |form|
        key = form.name.demodulize.underscore.downcase.dasherize.gsub(/-form$/, "")
        mapping[key] = form
      end

      mapping
    end

    def forms
      defined?(self::FORMS) ? self::FORMS : {}
    end

    def forms_mapping
      mapping = {}

      forms.map do |form|
        key = form.name.demodulize.underscore.downcase.dasherize.gsub(/-form$/, "")
        mapping[key] = form
      end

      mapping
    end
  end
end
