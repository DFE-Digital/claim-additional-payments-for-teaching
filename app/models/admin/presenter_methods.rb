module Admin
  module PresenterMethods
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TranslationHelper

    def display_school(school, include_dfe_number: true)
      tags = [link_to_school(school)]

      if include_dfe_number
        tags << tag.span("(#{school.dfe_number})", class: "govuk-body-s")
      end

      html = tags.join(" ").html_safe
      ActionController::Base.helpers.sanitize(html, tags: %w[span a], attributes: %w[href class])
    end

    def display_boolean(value)
      case value
      when false
        "No"
      when true
        "Yes"
      else
        "N/A"
      end
    end

    private

    def link_to_school(school)
      url = "https://get-information-schools.service.gov.uk/Establishments/Establishment/Details/#{school.urn}"

      link_text = [
        content_tag(:span, "View", class: "govuk-visually-hidden"),
        school.name,
        content_tag(:span, "on Get Information About Schools", class: "govuk-visually-hidden")
      ].join(" ").html_safe

      link_to(link_text, url, class: "govuk-link")
    end
  end
end
