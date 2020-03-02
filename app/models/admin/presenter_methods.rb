module Admin
  module PresenterMethods
    include ActionView::Helpers::UrlHelper

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
      link_to(school.name, url, class: "govuk-link")
    end
  end
end
