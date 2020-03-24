module Admin
  module PresenterMethods
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TranslationHelper

    def display_school(school)
      html = [
        link_to_school(school),
        tag.span("(#{school.dfe_number})", class: "govuk-body-s")
      ].join(" ").html_safe
      ActionController::Base.helpers.sanitize(html, tags: %w[span a], attributes: %w[href class])
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
