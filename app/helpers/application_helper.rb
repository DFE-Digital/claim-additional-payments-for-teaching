module ApplicationHelper
  def page_title(title, policy: nil, show_error: false)
    [].tap do |a|
      a << "Error" if show_error
      a << title
      a << policy_service_name(policy)
      a << "GOV.UK"
    end.join(" — ")
  end

  def claim_in_progress?
    session.key?(:claim_id)
  end

  def currency_value_for_number_field(value)
    return if value.nil?

    number_to_currency(value, delimiter: "", unit: "")
  end

  def support_email_address(routing_name = nil)
    return t("support_email_address") unless routing_name

    namespace = PolicyConfiguration.i18n_namespace_for_routing_name(routing_name)
    t("#{namespace}.support_email_address")
  end

  def policy_service_name(routing_name = nil)
    return t("service_name") unless routing_name

    namespace = PolicyConfiguration.i18n_namespace_for_routing_name(routing_name)
    t("#{namespace}.policy_name")
  end

  def policy_description(routing_name)
    namespace = PolicyConfiguration.i18n_namespace_for_routing_name(routing_name)
    t("#{namespace}.claim_description")
  end

  def feedback_url
    current_policy.feedback_url
  end

  def feedback_email
    current_policy.feedback_email
  end

  def start_page_url
    current_policy.start_page_url
  end

  def claim_decision_deadline_in_weeks
    "#{Claim::DECISION_DEADLINE.to_i / ActiveSupport::Duration::SECONDS_PER_WEEK} weeks"
  end

  def done_page_url
    "https://www.gov.uk/done/claim-additional-teaching-payment"
  end
end
