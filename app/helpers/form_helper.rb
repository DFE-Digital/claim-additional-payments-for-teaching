module FormHelper
  def form_group_tag(object, attribute = nil, &block)
    css_classes = ["govuk-form-group"]
    case attribute
    when Symbol
      css_classes += ["govuk-form-group--error"] if object.errors.key?(attribute)
    else
      css_classes += ["govuk-form-group--error"] if object.errors.any?
    end
    content_tag(:div, class: css_classes) do
      yield
    end
  end

  def errors_tag(object, attribute)
    return if object.errors.empty?
    messages = object.errors.messages[attribute]

    messages.map! do |message|
      content_tag(:span, "Error: ", class: "govuk-visually-hidden") + message
    end
    content_tag(:span, messages.join("</br>").html_safe, class: "govuk-error-message", id: error_id(object.class.model_name.singular, attribute))
  end

  def css_classes_for_select(object, attribute, css_classes = "")
    css_classes = css_classes.split
    css_classes += ["govuk-select"]
    css_classes += ["govuk-select--error"] if object.errors.key?(attribute)
    css_classes.join(" ")
  end

  def css_classes_for_input(object, attribute, css_classes = "")
    css_classes = css_classes.split
    css_classes += ["govuk-input"]
    css_classes += ["govuk-input--error"] if object.errors.key?(attribute)
    css_classes.join(" ")
  end

  private

  def error_id(object_name, attribute)
    "#{object_name}_#{attribute}-error"
  end
end
