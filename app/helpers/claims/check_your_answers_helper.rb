module Claims
  module CheckYourAnswersHelper
    def send_your_application(claim)
      if claim.has_ecp_policy?
        content_tag(:h2, I18n.t("early_career_payments.check_your_answers.heading_send_application"), class: "govuk-heading-m")
      else
        content_tag(:h2, I18n.t("check_your_answers.heading_send_application"), class: "govuk-heading-m")
      end
    end

    def statement(claim)
      if claim.has_ecp_policy?
        content_tag(:p, I18n.t("early_career_payments.check_your_answers.statement"), class: "govuk-body")
      else
        content_tag(:p, I18n.t("check_your_answers.statement"), class: "govuk-body")
      end
    end

    def submit_text(claim)
      if claim.has_ecp_policy?
        I18n.t("early_career_payments.check_your_answers.btn_text")
      else
        I18n.t("check_your_answers.btn_text")
      end
    end
  end
end
