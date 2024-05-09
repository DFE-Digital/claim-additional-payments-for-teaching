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
      address_line_1: address_line_1,
      address_line_2: address_line_2,
      address_line_3: address_line_3,
      address_line_4: address_line_4,
      postcode: postcode,
      date_of_birth: date_of_birth,
      teacher_reference_number: teacher_reference_number,
      national_insurance_number: national_insurance_number,
      email_address: email_address,
      bank_sort_code: bank_sort_code,
      bank_account_number: bank_account_number,
      details_check: details_check,
      payroll_gender: payroll_gender,
      first_name: first_name,
      middle_name: middle_name,
      surname: surname,
      banking_name: banking_name,
      building_society_roll_number: building_society_roll_number,
      academic_year: academic_year,
      bank_or_building_society: bank_or_building_society,
      provide_mobile_number: provide_mobile_number,
      mobile_number: mobile_number,
      email_verified: email_verified,
      mobile_verified: mobile_verified,
      hmrc_bank_validation_succeeded: hmrc_bank_validation_succeeded,
      hmrc_bank_validation_responses: hmrc_bank_validation_responses,
      logged_in_with_tid: logged_in_with_tid,
      teacher_id_user_info: teacher_id_user_info,
      email_address_check: email_address_check,
      mobile_check: mobile_check,
      qualifications_details_check: qualifications_details_check,
      nqt_in_academic_year_after_itt: nqt_in_academic_year_after_itt,
      employed_as_supply_teacher: employed_as_supply_teacher,
      qualification: qualification,
      has_entire_term_contract: has_entire_term_contract,
      employed_directly: employed_directly,
      subject_to_disciplinary_action: subject_to_disciplinary_action,
      subject_to_formal_performance_action: subject_to_formal_performance_action,
      eligible_itt_subject: eligible_itt_subject,
      eligible_degree_subject: eligible_degree_subject,
      teaching_subject_now: teaching_subject_now,
      itt_academic_year: itt_academic_year,
      current_school_id: current_school_id,
      induction_completed: induction_completed,
      school_somewhere_else: school_somewhere_else,
      qts_award_year: qts_award_year,
      claim_school_id: claim_school_id,
      employment_status: employment_status,
      biology_taught: biology_taught,
      chemistry_taught: chemistry_taught,
      computing_taught: computing_taught,
      languages_taught: languages_taught,
      physics_taught: physics_taught,
      taught_eligible_subjects: taught_eligible_subjects,
      student_loan_repayment_amount: student_loan_repayment_amount,
      had_leadership_position: had_leadership_position,
      mostly_performed_leadership_duties: mostly_performed_leadership_duties,
      claim_school_somewhere_else: claim_school_somewhere_else
    }
  end

  private

  def selected_policy
    journey_session.answers[:selected_policy] || current_claim.selected_policy
  end

  def address_line_1
    journey_session.answers[:address_line_1] || current_claim.address_line_1
  end

  def address_line_2
    journey_session.answers[:address_line_2] || current_claim.address_line_2
  end

  def address_line_3
    journey_session.answers[:address_line_3] || current_claim.address_line_3
  end

  def address_line_4
    journey_session.answers[:address_line_4] || current_claim.address_line_4
  end

  def postcode
    journey_session.answers[:postcode] || current_claim.postcode
  end

  def date_of_birth
    journey_session.answers[:date_of_birth] || current_claim.date_of_birth
  end

  def teacher_reference_number
    journey_session.answers[:teacher_reference_number] || current_claim.teacher_reference_number
  end

  def national_insurance_number
    journey_session.answers[:national_insurance_number] || current_claim.national_insurance_number
  end

  def email_address
    journey_session.answers[:email_address] || current_claim.email_address
  end

  def bank_sort_code
    journey_session.answers[:bank_sort_code] || current_claim.bank_sort_code
  end

  def bank_account_number
    journey_session.answers[:bank_account_number] || current_claim.bank_account_number
  end

  def details_check
    journey_session.answers[:details_check] || current_claim.details_check
  end

  def payroll_gender
    journey_session.answers[:payroll_gender] || current_claim.payroll_gender
  end

  def first_name
    journey_session.answers[:first_name] || current_claim.first_name
  end

  def middle_name
    journey_session.answers[:middle_name] || current_claim.middle_name
  end

  def surname
    journey_session.answers[:surname] || current_claim.surname
  end

  def banking_name
    journey_session.answers[:banking_name] || current_claim.banking_name
  end

  def building_society_roll_number
    journey_session.answers[:building_society_roll_number] || current_claim.building_society_roll_number
  end

  def academic_year
    journey_session.answers[:academic_year] || current_claim.academic_year
  end

  def bank_or_building_society
    journey_session.answers[:bank_or_building_society] || current_claim.bank_or_building_society
  end

  def provide_mobile_number
    journey_session.answers[:provide_mobile_number] || current_claim.provide_mobile_number
  end

  def mobile_number
    journey_session.answers[:mobile_number] || current_claim.mobile_number
  end

  def email_verified
    journey_session.answers[:email_verified] || current_claim.email_verified
  end

  def mobile_verified
    journey_session.answers[:mobile_verified] || current_claim.mobile_verified
  end

  def hmrc_bank_validation_succeeded
    journey_session.answers[:hmrc_bank_validation_succeeded] || current_claim.hmrc_bank_validation_succeeded
  end

  def hmrc_bank_validation_responses
    journey_session.answers[:hmrc_bank_validation_responses] || current_claim.hmrc_bank_validation_responses
  end

  def logged_in_with_tid
    journey_session.answers[:logged_in_with_tid] || current_claim.logged_in_with_tid
  end

  def teacher_id_user_info
    journey_session.answers[:teacher_id_user_info] || current_claim.teacher_id_user_info
  end

  def email_address_check
    journey_session.answers[:email_address_check] || current_claim.email_address_check
  end

  def mobile_check
    journey_session.answers[:mobile_check] || current_claim.mobile_check
  end

  def qualifications_details_check
    journey_session.answers[:qualifications_details_check] || current_claim.qualifications_details_check
  end

  def nqt_in_academic_year_after_itt
    journey_session.answers[:nqt_in_academic_year_after_itt] || try_eligibility(:nqt_in_academic_year_after_itt)
  end

  def employed_as_supply_teacher
    journey_session.answers[:employed_as_supply_teacher] || try_eligibility(:employed_as_supply_teacher)
  end

  def qualification
    journey_session.answers[:qualification] || try_eligibility(:qualification)
  end

  def has_entire_term_contract
    journey_session.answers[:has_entire_term_contract] || try_eligibility(:has_entire_term_contract)
  end

  def employed_directly
    journey_session.answers[:employed_directly] || try_eligibility(:employed_directly)
  end

  def subject_to_disciplinary_action
    journey_session.answers[:subject_to_disciplinary_action] || try_eligibility(:subject_to_disciplinary_action)
  end

  def subject_to_formal_performance_action
    journey_session.answers[:subject_to_formal_performance_action] || try_eligibility(:subject_to_formal_performance_action)
  end

  def eligible_itt_subject
    journey_session.answers[:eligible_itt_subject] || try_eligibility(:eligible_itt_subject)
  end

  def eligible_degree_subject
    journey_session.answers[:eligible_degree_subject] || try_eligibility(:eligible_degree_subject)
  end

  def teaching_subject_now
    journey_session.answers[:teaching_subject_now] || try_eligibility(:teaching_subject_now)
  end

  def itt_academic_year
    journey_session.answers[:itt_academic_year] || try_eligibility(:itt_academic_year)
  end

  def current_school_id
    journey_session.answers[:current_school_id] || try_eligibility(:current_school_id)
  end

  def induction_completed
    journey_session.answers[:induction_completed] || try_eligibility(:induction_completed)
  end

  def school_somewhere_else
    journey_session.answers[:school_somewhere_else] || try_eligibility(:school_somewhere_else)
  end

  def qts_award_year
    journey_session.answers[:qts_award_year] || try_eligibility(:qts_award_year)
  end

  def claim_school_id
    journey_session.answers[:claim_school_id] || try_eligibility(:claim_school_id)
  end

  def employment_status
    journey_session.answers[:employment_status] || try_eligibility(:employment_status)
  end

  def biology_taught
    journey_session.answers[:biology_taught] || try_eligibility(:biology_taught)
  end

  def chemistry_taught
    journey_session.answers[:chemistry_taught] || try_eligibility(:chemistry_taught)
  end

  def computing_taught
    journey_session.answers[:computing_taught] || try_eligibility(:computing_taught)
  end

  def languages_taught
    journey_session.answers[:languages_taught] || try_eligibility(:languages_taught)
  end

  def physics_taught
    journey_session.answers[:physics_taught] || try_eligibility(:physics_taught)
  end

  def taught_eligible_subjects
    journey_session.answers[:taught_eligible_subjects] || try_eligibility(:taught_eligible_subjects)
  end

  def student_loan_repayment_amount
    journey_session.answers[:student_loan_repayment_amount] || try_eligibility(:student_loan_repayment_amount)
  end

  def had_leadership_position
    journey_session.answers[:had_leadership_position] || try_eligibility(:had_leadership_position)
  end

  def mostly_performed_leadership_duties
    journey_session.answers[:mostly_performed_leadership_duties] || try_eligibility(:mostly_performed_leadership_duties)
  end

  def claim_school_somewhere_else
    journey_session.answers[:claim_school_somewhere_else] || try_eligibility(:claim_school_somewhere_else)
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
