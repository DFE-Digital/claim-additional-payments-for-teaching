class IneligibilityReasonChecker
  def initialize(answers)
    @answers = answers
  end

  def reason
    if ecp_only_and_ecp_closed?
      :ecp_only_ecp_closed
    elsif current_school?
      :current_school
    elsif dqt_data_ineligible?
      :dqt_data_ineligible
    elsif ecp_only_teacher_with_ineligible_itt_year?
      :ecp_only_teacher_with_ineligible_itt_year
    elsif teacher_with_ineligible_itt_year?
      :teacher_with_ineligible_itt_year
    elsif generic?
      :generic
    elsif trainee_teacher_last_policy_year?
      :trainee_in_last_policy_year
    elsif ecp_only_induction_not_completed?
      :ecp_only_induction_not_completed
    elsif ecp_only_trainee_teacher?
      :ecp_only_trainee_teacher
    elsif trainee_teaching_lacking_both_valid_itt_subject_and_degree?
      :trainee_teaching_lacking_both_valid_itt_subject_and_degree
    elsif lack_both_valid_itt_subject_and_degree?
      :lack_both_valid_itt_subject_and_degree
    elsif would_be_eligible_for_lup_only_except_for_insufficient_teaching?
      :would_be_eligible_for_lup_only_except_for_insufficient_teaching
    elsif would_be_eligible_for_ecp_only_except_for_insufficient_teaching?
      :would_be_eligible_for_ecp_only_except_for_insufficient_teaching
    elsif would_be_eligible_for_both_ecp_and_lup_except_for_insufficient_teaching?
      :would_be_eligible_for_both_ecp_and_lup_except_for_insufficient_teaching
    elsif bad_itt_year_for_ecp?
      :bad_itt_year_for_ecp
    elsif bad_itt_subject_for_ecp?
      :bad_itt_subject_for_ecp
    elsif no_ecp_subjects_that_itt_year?
      :no_ecp_subjects_that_itt_year
    end
  end

  private

  def ecp_only_and_ecp_closed?
    school = @answers.current_school

    [
      Policies::EarlyCareerPayments::SchoolEligibility.new(school).eligible?,
      !Policies::LevellingUpPremiumPayments::SchoolEligibility.new(school).eligible?
    ].all? && Policies::EarlyCareerPayments.closed?(@answers.policy_year)
  end

  def current_school?
    school = @answers.current_school

    [
      school.present?,
      !Policies::EarlyCareerPayments::SchoolEligibility.new(school).eligible?,
      !Policies::LevellingUpPremiumPayments::SchoolEligibility.new(school).eligible?
    ].all?
  end

  def dqt_data_ineligible?
    @answers.logged_in_with_tid? && @answers.qualifications_details_check && [
      @answers.itt_academic_year == AcademicYear.new,
      bad_itt_year_for_ecp?,
      bad_itt_subject_for_ecp?,
      no_ecp_subjects_that_itt_year?,
      lack_both_valid_itt_subject_and_degree?,
      trainee_teaching_lacking_both_valid_itt_subject_and_degree?
    ].any?
  end

  def ecp_only_teacher_with_ineligible_itt_year?
    [
      @answers.itt_academic_year == AcademicYear.new,
      school_eligible_for_ecp_but_not_lup?(@answers.current_school)
    ].all?
  end

  def teacher_with_ineligible_itt_year?
    [
      @answers.itt_academic_year == AcademicYear.new,
      Policies::LevellingUpPremiumPayments::SchoolEligibility.new(@answers.current_school).eligible?
    ].all?
  end

  def generic?
    [
      @answers.has_entire_term_contract == false,
      @answers.employed_directly == false,
      @answers.subject_to_formal_performance_action?,
      @answers.subject_to_disciplinary_action?
    ].any?
  end

  def ecp_only_induction_not_completed?
    [
      school_eligible_for_ecp_but_not_lup?(@answers.current_school),
      @answers.induction_not_completed?
    ].all?
  end

  def ecp_only_trainee_teacher?
    [
      !Policies::LevellingUpPremiumPayments::SchoolEligibility.new(@answers.current_school).eligible?,
      @answers.nqt_in_academic_year_after_itt == false
    ].all?
  end

  def trainee_teaching_lacking_both_valid_itt_subject_and_degree?
    [
      Policies::LevellingUpPremiumPayments::SchoolEligibility.new(@answers.current_school).eligible?,
      @answers.nqt_in_academic_year_after_itt == false,
      lack_both_valid_itt_subject_and_degree?
    ].all?
  end

  def lack_both_valid_itt_subject_and_degree?
    [
      subject_invalid_for_ecp?,
      @answers.eligible_degree_subject == false
    ].all?
  end

  def would_be_eligible_for_lup_only_except_for_insufficient_teaching?
    would_be_eligible_for_one_policy_only_except_for_insufficient_teaching?(Policies::LevellingUpPremiumPayments)
  end

  def would_be_eligible_for_one_policy_only_except_for_insufficient_teaching?(policy)
    other_policy = (policy == Policies::EarlyCareerPayments) ? Policies::LevellingUpPremiumPayments : Policies::EarlyCareerPayments

    [
      eligible_with_sufficient_teaching?(policy),
      !eligible_with_sufficient_teaching?(other_policy)
    ].all?
  end

  def eligible_with_sufficient_teaching?(policy)
    teaching_before = @answers.teaching_subject_now

    # check it and put it back
    @answers.teaching_subject_now = true
    eligible_with_sufficient_teaching = policy::PolicyEligibilityChecker.new(answers: @answers).status.in?([:eligible_now, :eligible_later])
    @answers.teaching_subject_now = teaching_before

    eligible_with_sufficient_teaching
  end

  def would_be_eligible_for_ecp_only_except_for_insufficient_teaching?
    would_be_eligible_for_one_policy_only_except_for_insufficient_teaching?(Policies::EarlyCareerPayments)
  end

  def would_be_eligible_for_both_ecp_and_lup_except_for_insufficient_teaching?
    [
      eligible_with_sufficient_teaching?(Policies::EarlyCareerPayments),
      eligible_with_sufficient_teaching?(Policies::LevellingUpPremiumPayments)
    ].all?
  end

  def subject_invalid_for_ecp?
    !@answers.eligible_itt_subject&.to_sym&.in?(ecp_subject_options)
  end

  def ecp_subject_options
    Policies::EarlyCareerPayments.current_and_future_subject_symbols(
      claim_year: @answers.policy_year,
      itt_year: @answers.itt_academic_year
    )
  end

  def bad_itt_year_for_ecp?
    [
      ecp_subject_options.one?,
      subject_invalid_for_ecp?,
      school_eligible_for_ecp_but_not_lup?(@answers.current_school)
    ].all?
  end

  def school_eligible_for_ecp_but_not_lup?(school)
    Policies::EarlyCareerPayments::SchoolEligibility.new(school).eligible? && !Policies::LevellingUpPremiumPayments::SchoolEligibility.new(school).eligible?
  end

  def bad_itt_subject_for_ecp?
    [
      ecp_subject_options.many?,
      subject_invalid_for_ecp?,
      school_eligible_for_ecp_but_not_lup?(@answers.current_school)
    ].all?
  end

  def no_ecp_subjects_that_itt_year?
    [
      ecp_subject_options.none?,
      school_eligible_for_ecp_but_not_lup?(@answers.current_school)
    ].all?
  end

  def trainee_teacher_last_policy_year?
    [
      @answers.nqt_in_academic_year_after_itt == false,
      @answers.academic_year >= AcademicYear.new(Policies::LevellingUpPremiumPayments::POLICY_END_YEAR),
      @answers.academic_year >= AcademicYear.new(Policies::EarlyCareerPayments::POLICY_END_YEAR)
    ].all?
  end
end
