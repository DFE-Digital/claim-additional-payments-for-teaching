# frozen_string_literal: true

require "academic_year"

# Module namespace specific to the policy for claiming a payment for teaching
# maths or physics.
#
# This payment is available to Maths or Physics teachers in the first five their
# career employed in state-funded secondary schools in eligible local
# authorities. Full details of the eligibility criteria can be found at the URL
# defined by `MathsAndPhysics.eligibility_page_url`.
module MathsAndPhysics
  extend self

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
    "maths-and-physics"
  end

  def notify_reply_to_id
    "29493350-ceec-4142-bd29-34ee363d5f62"
  end

  def feedback_url
    "https://docs.google.com/forms/d/e/1FAIpQLSfwPUxmNHqSnQ6RJ-0nedu5F2FRibBF5UIJ_EciTPcWQg581A/viewform"
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
  def first_eligible_qts_award_year
    AcademicYear.new(configuration.current_academic_year) - 5
  end

  def configuration
    PolicyConfiguration.for(self)
  end
end
