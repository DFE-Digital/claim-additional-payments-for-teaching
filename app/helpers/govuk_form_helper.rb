module GovukFormHelper
  # = GOVUK Form Tag Helpers
  #
  # For usage, components and patterns see:
  # https://design-system.service.gov.uk/

  # Can be used to wrap multiple or single components.
  #
  # Creates a div with the 'govuk-form-group' css class, if the provided object has errors, adds
  # the 'govuk-form-group--error' css class.
  #
  # Passing the attribute symbol will only add the error class if the object contains errors for
  # the matching symbol.
  #
  # Generally pass only an object when wrapping multiple components and pass an object and attribute when
  # wrapping a single component.
  #
  # === Examples
  # ==== Wrap multiple components
  #
  #   <%= form_group_tag object do %>
  #     <fieldset class="govuk-fieldset">
  #       <legend class="govuk-fieldset__legend govuk-fieldset__legend--xl">
  #         <h1 class="govuk-fieldset__heading">
  #           Where do you live?
  #         </h1>
  #       </legend>
  #     ...
  #     </fieldset>
  #   <% end %>
  #
  #   <div class="govuk-form-group">
  #     <fieldset class="govuk-fieldset">
  #       <legend class="govuk-fieldset__legend govuk-fieldset__legend--xl">
  #         <h1 class="govuk-fieldset__heading">
  #           Where do you live?
  #         </h1>
  #       </legend>
  #        ...
  #     </fieldset>
  #   </div>
  #
  # ==== Wrap a single component
  #
  #   <%= form_group_tag object, :event_name do %>
  #     ...
  #   <% end %>
  #
  #   <div class="govuk-form-group">
  #     <label class="govuk-label" for="object_event_name">
  #       Event name
  #     </label>
  #     <input class="govuk-input" id="object_event_name" name="event_name" type="text">
  #   </div>
  #
  def form_group_tag(object, attribute = nil, &block)
    css_classes = ["govuk-form-group"]
    if attribute.present? && object.errors.key?(attribute)
      css_classes << "govuk-form-group--error"
    elsif attribute.nil? && object.errors.any?
      css_classes << "govuk-form-group--error"
    end
    content_tag(:div, class: css_classes) do
      yield
    end
  end

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
    content_tag(:span, messages.join("<br>").html_safe, {class: "govuk-error-message", id: error_id(object.class.model_name.singular, attribute)})
  end

  # Returns a string of the GOVUK css classes for the +<select>+ html element along with any
  # existing css classes provided.
  #
  # When _object_ contains errors for _attribute_ the 'govuk-input--error' css class is added.
  #
  # === Example
  #
  # css_classes_for_select(object, :attribute, "another-css-class")
  #
  #   "govuk-select another-css-class"
  #
  def css_classes_for_select(object, attribute, css_classes = "")
    css_classes = css_classes.split
    css_classes << "govuk-select"
    css_classes << "govuk-select--error" if object.errors.key?(attribute)
    css_classes.join(" ")
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
