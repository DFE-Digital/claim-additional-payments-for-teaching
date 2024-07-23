module FormHelpers
  def i18n_namespace
    journey::I18N_NAMESPACE
  end

  def i18n_errors_path(key, args = {})
    base_key = :"forms.#{i18n_form_namespace}.errors.#{key}"
    I18n.t("#{i18n_namespace}.#{base_key}", default: base_key, **args)
  end

  def t(key, args = {})
    i18n_form_namespace_dup = args.delete(:i18n_form_namespace) || i18n_form_namespace

    base_key = :"forms.#{i18n_form_namespace_dup}.#{key}"
    I18n.t("#{i18n_namespace}.#{base_key}", default: base_key, **args)
  end

  private

  def i18n_form_namespace
    self.class.name.demodulize.gsub("Form", "").underscore
  end
end
