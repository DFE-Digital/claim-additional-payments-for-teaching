# frozen_string_literal: true

# Module namespace specific to the policy for claiming early-career payments.
#
# Early-career payments are available to teachers starting their initial teacher training (ITT)
# in the Academic Years 2018 to 2019, 2019 to 2020 or 2020 to 2021 academic year.
# This is in addition to receiving a bursary or scholarship during ITT.
# Full details of the eligibility criteria can be found at the URL
# defined by `EarlyCareerPayments.eligibility_page_url`.
module EarlyCareerPayments
  extend self

  POLICY_START_YEAR = AcademicYear.new(2021).freeze

  def start_page_url
    if Rails.env.production?
      "https://www.gov.uk/guidance/early-career-payments-guidance-for-teachers-and-schools"
    else
      "/#{routing_name}/claim"
    end
  end

  def eligibility_page_url
    "https://www.gov.uk/guidance/early-career-payments-guidance-for-teachers-and-schools"
  end

  def routing_name
    PolicyConfiguration.routing_name_for_policy(self)
  end

  def policy_type
    name.underscore.dasherize
  end

  def locale_key
    routing_name.underscore
  end

  def notify_reply_to_id
    "3f85a1f7-9400-4b48-9a31-eaa643d6b977"
  end

  def feedback_url
    "https://docs.google.com/forms/TO-BE-REPLACED-by-response-to-ECP-509/viewform"
  end

  def feedback_email
    "earlycareerteacherpayments@digital.education.gov.uk"
  end

  def short_name
    I18n.t("early_career_payments.policy_short_name")
  end

  def first_eligible_qts_award_year(claim_year = nil)
    POLICY_START_YEAR
  end

  def last_ineligible_qts_award_year
    first_eligible_qts_award_year - 1
  end

  def student_loan_balance_url
    "https://www.gov.uk/sign-in-to-manage-your-student-loan-balance"
  end

  def configuration
    PolicyConfiguration.for(self)
  end
end
