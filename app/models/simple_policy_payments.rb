# frozen_string_literal: true

module SimplePolicyPayments
  module_function

  ACADEMIC_YEARS_QUALIFIED_TEACHERS_CAN_CLAIM_FOR = 2

  def start_page_url
    if Rails.env.production?
      # TODO: provided by the GOV UK publishing team
      'https://www.gov.uk/guidance/simple-policy-payments'
    else
      "/#{routing_name}/claim"
    end
  end

  def eligibility_page_url
    # TODO: provided by the GOV UK publishing team
    'https://www.gov.uk/guidance/simple-policy-payments'
  end

  def routing_name
    PolicyConfiguration.routing_name_for_policy(self)
  end

  def policy_type
    name.underscore.dasherize
  end

  def locale_key
    name.underscore
  end

  def notify_reply_to_id
    # TODO: found within the Notify application
    'made-up-random-guid'
  end

  def feedback_url
    # TODO: use a GOV UK Form for this and send to feedback_email
    'https://docs.example.com/viewform'
  end

  def feedback_email
    # TODO: setup a shared mailbox for this policy
    'simple-policy-payments@digital.education.gov.uk'
  end

  def first_eligible_qts_award_year(claim_year = nil)
    claim_year ||= configuration.current_academic_year
    claim_year - ACADEMIC_YEARS_QUALIFIED_TEACHERS_CAN_CLAIM_FOR
  end

  def last_ineligible_qts_award_year
    first_eligible_qts_award_year - 1
  end

  def short_name
    I18n.t('simple_policy_payments.policy_short_name')
  end

  def configuration
    PolicyConfiguration.for(self)
  end
end
