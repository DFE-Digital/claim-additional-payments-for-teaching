# frozen_string_literal: true

# Module namespace specific to the policy for claiming a payment for teaching
# maths or physics.
#
# This payment is available to Maths or Physics teachers in the first five their
# career employed in state-funded secondary schools in eligible local
# authorities. Full details of the eligibility criteria can be found at the URL
# defined by `MathsAndPhysics.eligibility_page_url`.
module MathsAndPhysics
  extend self

  ELIGIBLE_CAREER_LENGTH = 5

  def start_page_url
    if Rails.env.production?
      "https://www.gov.uk/guidance/claim-a-payment-for-teaching-maths-or-physics"
    else
      "/#{routing_name}/claim"
    end
  end

  def eligibility_page_url
    "https://www.gov.uk/government/publications/additional-payments-for-teaching-eligibility-and-payment-details/claim-a-payment-for-teaching-maths-or-physics-eligibility-and-payment-details"
  end

  def routing_name
    Journey.routing_name_for_policy(self)
  end

  def locale_key
    routing_name.underscore
  end

  def notify_reply_to_id
    "29493350-ceec-4142-bd29-34ee363d5f62"
  end

  def feedback_url
    "https://docs.google.com/forms/d/e/1FAIpQLSfwPUxmNHqSnQ6RJ-0nedu5F2FRibBF5UIJ_EciTPcWQg581A/viewform"
  end

  def feedback_email
    "mathsphysicsteacherpayment@digital.education.gov.uk"
  end

  def short_name
    I18n.t("maths_and_physics.policy_short_name")
  end

  # Returns the AcademicYear during or after which teachers must have completed
  # their Initial Teacher Training and been awarded QTS to be eligible to make
  # a claim. Anyone qualifying before this academic year should not be able to
  # make a claim.
  #
  # Maths & Physics teachers are eligible to claim if they are in the first five
  # years of their career.
  def first_eligible_qts_award_year(claim_year = nil)
    claim_year ||= configuration.current_academic_year
    claim_year - ELIGIBLE_CAREER_LENGTH
  end

  def last_ineligible_qts_award_year
    first_eligible_qts_award_year - 1
  end

  def configuration
    PolicyConfiguration.for(self)
  end
end
