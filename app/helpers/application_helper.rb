require "pathname"

module ApplicationHelper
  def page_title(title, journey: nil, show_error: false)
    [].tap do |a|
      a << "Error" if show_error
      a << title
      a << journey_service_name(journey)
      a << "GOV.UK"
    end.join(" — ")
  end

  def header_link(current_journey_routing_name)
    link_to journey_service_name(current_journey_routing_name), start_page_url(current_journey_routing_name), class: "govuk-header__link govuk-header__service-name"
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

  def feedback_email(routing_name)
    namespace = Journeys.for_routing_name(routing_name)::I18N_NAMESPACE
    t("#{namespace}.feedback_email")
  end

  def start_page_url(routing_name)
    Journeys.for_routing_name(routing_name).start_page_url
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

  def one_login_home_url
    OneLogin::Config.home_url
  end

  def hide_cookie_banner?
    return unless cookies.encrypted[:accept_cookies].present?

    hash = JSON.parse(cookies.encrypted[:accept_cookies])

    !hash["state"].nil?
  end

  def hide_accepted_cookie_banner?
    return true unless cookies.encrypted[:accept_cookies].present?

    hash = JSON.parse(cookies.encrypted[:accept_cookies])

    !(hash["state"] && hash["message"])
  end

  def hide_rejected_cookie_banner?
    return true unless cookies.encrypted[:accept_cookies].present?

    hash = JSON.parse(cookies.encrypted[:accept_cookies])

    !(!hash["state"] && hash["message"])
  end

  def cookies_accepted?
    return unless cookies.encrypted[:accept_cookies].present?

    hash = JSON.parse(cookies.encrypted[:accept_cookies])

    hash["state"]
  end

  def admin_nav_items
    [
      {text: "Claims", href: admin_claims_path, active_when: /^(?!#{search_admin_claims_path})#{admin_claims_path}/},
      {text: "Search", href: search_admin_claims_path, active_when: search_admin_claims_path},
      {text: "Payroll", href: admin_payroll_runs_path, active_when: admin_payroll_runs_path},
      {text: "Manage services", href: admin_journey_configurations_path, active_when: admin_journey_configurations_path},
      {text: "Reports", href: admin_reports_path, active_when: admin_reports_path},
      {text: "Sign out", href: admin_sign_out_path}
    ]
  end

  def footer_links
    [
      {
        text: "Contact us",
        href: contact_us_path(current_journey_routing_name)
      },
      {
        text: "Cookies",
        href: cookies_path(current_journey_routing_name)
      },
      {
        text: "Terms and conditions",
        href: terms_conditions_path(current_journey_routing_name)
      },
      {
        text: "Privacy notice",
        href: "https://www.gov.uk/government/publications/privacy-information-education-providers-workforce-including-teachers/privacy-information-education-providers-workforce-including-teachers"
      },
      {
        text: "Accessibility statement",
        href: accessibility_statement_path(current_journey_routing_name)
      }
    ]
  end

  def admin_footer_links
    [
      {
        text: "Cookies",
        href: admin_cookies_path
      },
      {
        text: "Accessibility statement",
        href: admin_accessibility_statement_path
      }
    ]
  end

  def provider_nav_items
    if current_user.null_user?
      []
    else
      [
        {
          text: "Unverified claims",
          href: further_education_payments_providers_claims_path,
          active_when: further_education_payments_providers_claims_path
        },
        {
          text: "Verified claims",
          href: further_education_payments_providers_verified_claims_path,
          active_when: further_education_payments_providers_verified_claims_path
        },
        {
          text: "Sign out",
          href: further_education_payments_providers_session_path
        }
      ]
    end
  end
end
