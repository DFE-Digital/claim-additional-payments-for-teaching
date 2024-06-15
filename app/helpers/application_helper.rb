module ApplicationHelper
  def page_title(title, journey: nil, show_error: false)
    [].tap do |a|
      a << "Error" if show_error
      a << title
      a << journey_service_name(journey)
      a << "GOV.UK"
    end.join(" — ")
  end

  def currency_value_for_number_field(value)
    return if value.nil?

    number_to_currency(value, delimiter: "", unit: "")
  end

  def support_email_address(routing_name = nil)
    return t("support_email_address") unless routing_name

    namespace = Journeys.for_routing_name(routing_name)::I18N_NAMESPACE
    t("#{namespace}.support_email_address")
  end

  def journey_service_name(routing_name = nil)
    return t("service_name") unless routing_name

    namespace = Journeys.for_routing_name(routing_name)::I18N_NAMESPACE
    t("#{namespace}.journey_name")
  end

  def journey_description(routing_name)
    namespace = Journeys.for_routing_name(routing_name)::I18N_NAMESPACE
    t("#{namespace}.claim_description")
  end

  def feedback_email(routing_name)
    namespace = Journeys.for_routing_name(routing_name)::I18N_NAMESPACE
    t("#{namespace}.feedback_email")
  end

  def start_page_url(routing_name)
    Journeys.for_routing_name(routing_name).start_page_url
  end

  def eligibility_page_url
    current_claim.policy.eligibility_page_url
  end

  def claim_decision_deadline_in_weeks
    "#{Claim::DECISION_DEADLINE.to_i / ActiveSupport::Duration::SECONDS_PER_WEEK} weeks"
  end

  def done_page_url
    "https://www.gov.uk/done/claim-additional-teaching-payment"
  end

  def information_provided_further_details_with_link(policy:)
    text = I18n.t("#{policy.locale_key}.information_provided_further_details_link_text")
    link = link_to(text, policy.payment_and_deductions_info_url, class: "govuk-link govuk-link--no-visited-state", target: "_blank")

    I18n.t("#{policy.locale_key}.information_provided_further_details", link: link)&.html_safe
  end
end
