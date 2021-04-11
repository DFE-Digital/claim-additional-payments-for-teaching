# frozen_string_literal: true

# Module namespace specific to the policy for claiming early career payments.
#
# Early-career payments are available to teachers starting their initial teacher training (ITT)
# in the 2018 to 2019, 2019 to 2020 or 2020 to 2021 academic year.
# This is in addition to receiving a bursary or scholarship during ITT.
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
    "https://www.gov.uk/publications/TO-BE-REPLACED-by-response-to-ECP-518"
  end

  def routing_name
    "early-career-payments"
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

  def short_name
    I18n.t("early_career_payments.policy_short_name")
  end

  def first_eligible_qts_award_year(claim_year = nil)
    POLICY_START_YEAR
  end

  def last_ineligible_qts_award_year
    first_eligible_qts_award_year - 1
  end
end
