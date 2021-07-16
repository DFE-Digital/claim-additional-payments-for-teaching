module Claims
  module EmailAddressHelper
    def email_govuk_hint(claim)
      content_tag(:div, nil, class: "govuk-hint", id: "email-address-hint") do
        concat content_tag(:p, I18n.t("questions.email_address_hint1"))
        concat content_tag(:p, I18n.t("questions.email_address_hint2"))
      end
    end

    def personal_details_caption(claim)
      content_tag(:span, I18n.t("questions.personal_details"), class: "govuk-caption-xl")
    end
  end
end
