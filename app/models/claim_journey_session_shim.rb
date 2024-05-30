# Temp class to allow working with the current_claims and the journey_session.
# As each form is updated to write to the journey_session rather than the
# current_claim we can remove the corresponding methods and update the answers
# hash to pull it's answer directly from the journey_session. When all answers
# in the answers hash have been updated to only refer to the journey_session
# this class can be removed.

class ClaimJourneySessionShim
  attr_reader :current_claim, :journey_session

  delegate_missing_to :journey_session

  def initialize(current_claim:, journey_session:)
    @current_claim = current_claim
    @journey_session = journey_session
  end

  def answers
    {
      selected_policy: selected_policy,
      address_line_1: journey_session.answers.address_line_1,
      address_line_2: journey_session.answers.address_line_2,
      address_line_3: journey_session.answers.address_line_3,
      address_line_4: journey_session.answers.address_line_4,
      postcode: journey_session.answers.postcode,
      date_of_birth: journey_session.answers.date_of_birth,
      teacher_reference_number: teacher_reference_number,
      national_insurance_number: journey_session.answers.national_insurance_number,
      email_address: journey_session.answers.email_address,
      bank_sort_code: journey_session.answers.bank_sort_code,
      bank_account_number: journey_session.answers.bank_account_number,
      details_check: details_check,
      payroll_gender: payroll_gender,
      first_name: journey_session.answers.first_name,
      middle_name: journey_session.answers.middle_name,
      surname: journey_session.answers.surname,
      banking_name: journey_session.answers.banking_name,
      building_society_roll_number: journey_session.answers.building_society_roll_number,
      academic_year: academic_year,
      bank_or_building_society: journey_session.answers.bank_or_building_society,
      provide_mobile_number: journey_session.answers.provide_mobile_number,
      mobile_number: journey_session.answers.mobile_number,
      email_verified: journey_session.answers.email_verified,
      mobile_verified: journey_session.answers.mobile_verified,
      hmrc_bank_validation_succeeded: journey_session.answers.hmrc_bank_validation_succeeded,
      hmrc_bank_validation_responses: journey_session.answers.hmrc_bank_validation_responses,
      logged_in_with_tid: logged_in_with_tid,
      teacher_id_user_info: teacher_id_user_info,
      email_address_check: journey_session.answers.email_address_check,
      mobile_check: journey_session.answers.mobile_check,
      qualifications_details_check: qualifications_details_check
    }
  end

  private

  def selected_policy
    journey_session.answers.selected_policy || current_claim.selected_policy
  end

  def teacher_reference_number
    journey_session.answers.teacher_reference_number.presence || current_claim.teacher_reference_number
  end

  def details_check
    journey_session.answers.details_check || current_claim.details_check
  end

  def payroll_gender
    journey_session.answers.payroll_gender || current_claim.payroll_gender
  end

  def academic_year
    journey_session.answers.academic_year || current_claim.academic_year
  end

  def logged_in_with_tid
    journey_session.answers.logged_in_with_tid || current_claim.logged_in_with_tid
  end

  def teacher_id_user_info
    journey_session.answers.teacher_id_user_info || current_claim.teacher_id_user_info
  end

  def qualifications_details_check
    journey_session.answers.qualifications_details_check || current_claim.qualifications_details_check
  end

  def eligibilities
    @eligibilities ||= current_claim.claims.map(&:eligibility)
  end

  # Different journeys have different eligibility attributes
  # Some eligibilities on the same journey have different attributes eg
  # only levelling_up_premium_payments_eligibility has
  # `eligible_degree_subject`
  def try_eligibility(attr)
    if current_claim.eligibility.respond_to?(attr)
      current_claim.eligibility.send(attr)
    elsif (eligibility = eligibilities.detect { |e| e.respond_to?(attr) })
      eligibility.send(attr)
    end
  end
end
