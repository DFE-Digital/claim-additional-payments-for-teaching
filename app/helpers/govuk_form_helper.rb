module GovukFormHelper
  # Returns a set of +<span>+ tags that contains the error messages in _object_ that match the
  # _attribute_ symbol.
  #
  # === Examples
  #   errors_tag(object, :attribute)
  #
  #   <span id="object_attibute_name-error" class="govuk-error-message">
  #     <span class="govuk-visually-hidden">Error: </span>Error message one<br>
  #     <span class="govuk-visually-hidden">Error: </span>Error message two
  #   </span>
  #
  def errors_tag(object, attribute)
    return unless object.errors.messages[attribute].present?

    messages = object.errors.messages[attribute].map { |message| content_tag(:span, "Error:", class: "govuk-visually-hidden") + " " + message }
    content_tag(:span, messages.join("<br>").html_safe, {class: "govuk-error-message", id: error_id(object.model_name.singular, attribute)})
  end

  # Returns a string of the GOVUK css classes for the +<input>+ html element along with any
  # existing css classes provided.
  #
  # When _object_ contains errors for _attribute_ the 'govuk-input--error' css class is added.
  #
  # === Example
  #
  # css_classes_for_input(object, :attribute, "another-css-class")
  #
  #   "govuk-select another-css-class"
  #
  def css_classes_for_input(object, attribute, css_classes = "")
    css_classes = css_classes.split
    css_classes << "govuk-input"
    css_classes << "govuk-input--error" if object.errors.key?(attribute)
    css_classes.join(" ")
  end

  private

  def error_id(object_name, attribute)
    "#{object_name}_#{attribute}-error"
  end
end
