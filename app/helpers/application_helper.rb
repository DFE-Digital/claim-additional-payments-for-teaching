module ApplicationHelper
  def page_title(title, policy:, show_error: false)
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

  def support_email_address(policy = nil)
    translation_key = [policy&.underscore, "support_email_address"].compact.join(".")
    t(translation_key)
  end

  def policy_service_name(policy = nil)
    policy ? t("#{policy.underscore}.policy_name") : t("service_name")
  end

  def feedback_url
    current_policy.feedback_url
  end

  def start_page_url
    current_policy.start_page_url
  end

  def current_policy
    Policies[current_policy_routing_name]
  end

  def claim_checking_deadline_in_weeks
    "#{Claim::CHECK_DEADLINE.to_i / ActiveSupport::Duration::SECONDS_PER_WEEK} weeks"
  end
end
