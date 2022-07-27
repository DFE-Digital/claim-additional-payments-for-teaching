# Unfortunately we have to keep some legacy methods for now because a helper calls these
# private methods using `send`.
#
# A concern isn't really the right place to put these but gets them out of the way in the already
# bloated `Eligibility` classes. Ideally we'll delete this code.
module EarlyCareerPaymentsHelpable
  extend ActiveSupport::Concern

  # This method has *no* bearing on the actual eligibility of a ECP claim.
  # It was created for the EarlyCareerPaymentsHelper and is only to do with
  # displaying an eligibility reason
  def helper_generic_ineligibility?
    trainee_teacher? ||
      no_entire_term_contract? ||
      not_employed_directly? ||
      poor_performance? ||
      ineligible_cohort?
  end

  def ineligible_current_school?
    current_school.present? and !current_school.eligible_for_early_career_payments?
  end

  def not_employed_directly?
    employed_as_supply_teacher? && employed_directly == false
  end

  def not_teaching_now_in_eligible_itt_subject?
    teaching_subject_now == false
  end

  def no_entire_term_contract?
    employed_as_supply_teacher? && has_entire_term_contract == false
  end

  def trainee_teacher?
    nqt_in_academic_year_after_itt == false
  end

  def qualification_name
    return qualification.gsub("_itt", " initial teaching training") if qualification.split("_").last == "itt"

    qualification_attained = qualification.humanize.downcase

    qualification_attained == "assessment only" ? qualification_attained : qualification_attained + " qualification"
  end
end
