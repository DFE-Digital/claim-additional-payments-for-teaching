module Claims
  module EmailAddressHelper
    def email_govuk_hint(claim)
      if claim.has_ecp_policy?
        content_tag(:div, nil, class: "govuk-hint", id: "email-address-hint") do
          concat content_tag(:p, I18n.t("early_career_payments.email_address_hint1"))
          concat content_tag(:p, I18n.t("early_career_payments.email_address_hint2"))
        end
      else
        content_tag(:span, I18n.t("questions.email_address_hint"), class: "govuk-hint", id: "email-address-hint")
      end
    end

    def personal_details_caption(claim)
      content_tag(:span, I18n.t("early_career_payments.personal_details"), class: "govuk-caption-xl") if claim.has_ecp_policy?
    end
  end
end
