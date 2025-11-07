module FormHelpers
  def i18n_namespace
    journey.i18n_namespace
  end

  def i18n_errors_path(key, args = {})
    base_key = :"forms.#{i18n_form_namespace}.errors.#{key}"
    I18n.t("#{i18n_namespace}.#{base_key}", default: base_key, **args)
  end

  def t(key, args = {})
    key_string = case key
    when Array
      key.join(".")
    else
      key
    end

    i18n_form_namespace_dup = args.delete(:i18n_form_namespace) || i18n_form_namespace

    base_key = :"forms.#{i18n_form_namespace_dup}.#{key_string}"
    I18n.t("#{i18n_namespace}.#{base_key}", default: base_key, **args)
  end

  private

  def i18n_form_namespace
    self.class.name.demodulize.gsub("Form", "").underscore
  end
end
