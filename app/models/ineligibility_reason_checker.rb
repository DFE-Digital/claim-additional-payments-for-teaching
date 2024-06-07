class IneligibilityReasonChecker
  attr_reader :current_claim, :journey_session

  def initialize(current_claim:, journey_session:)
    @current_claim = current_claim
    @journey_session = journey_session

    @use_claim = true
  end

  def reason
    if current_school?
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

  def use_answers!
    @use_claim = false
  end

  private

  def use_claim?
    @use_claim
  end

  def answers
    journey_session.answers
  end

  def answer_or_eligibility_for(field)
    if (answer = answers.public_send(field)).nil?
      current_claim.eligibility.public_send(field)
    else
      answer
    end
  end

  def answer_or_claim_for(field)
    if (answer = answers.public_send(field)).nil?
      current_claim.public_send(field)
    else
      answer
    end
  end

  def current_school
    @school ||= answer_or_eligibility_for(:current_school)
  end

  def has_entire_term_contract
    @has_entire_term_contract ||= answer_or_eligibility_for(:has_entire_term_contract)
  end

  def employed_directly
    @employed_directly ||= answer_or_eligibility_for(:employed_directly)
  end

  def subject_to_formal_performance_action
    @subject_to_formal_performance_action ||= answer_or_eligibility_for(:subject_to_formal_performance_action)
  end

  def subject_to_disciplinary_action
    @subject_to_disciplinary_action ||= answer_or_eligibility_for(:subject_to_disciplinary_action)
  end

  def itt_academic_year
    @itt_academic_year ||= if (answer = answers.itt_academic_year).nil?
      current_claim.eligibility.itt_academic_year
    else
      AcademicYear.new(answer)
    end
  end

  def logged_in_with_tid
    @logged_in_with_tid ||= if (answer = answers.logged_in_with_tid).nil?
      current_claim.logged_in_with_tid?
    else
      answer
    end
  end

  def qualifications_details_check
    @qualifications_details_check ||= answer_or_claim_for(:qualifications_details_check)
  end

  def eligible_degree_subject
    return @eligible_degree_subject if @eligible_degree_subject

    @eligible_degree_subject ||= if (answer = answers.eligible_degree_subject).nil?
      lup_claim.eligibility.eligible_degree_subject
    else
      answer
    end
  end

  def lup_claim
    @lup_claim ||= current_claim.for_policy(Policies::LevellingUpPremiumPayments)
  end

  def nqt_in_academic_year_after_itt
    @nqt_in_academic_year_after_itt ||= answer_or_eligibility_for(:nqt_in_academic_year_after_itt)
  end

  def academic_year
    @academic_year ||= answer_or_eligibility_for(:academic_year)
  end

  def eligible_itt_subject
    @eligible_itt_subject ||= answer_or_eligibility_for(:eligible_itt_subject)
  end

  def current_school?
    [
      current_school.present?,
      !Policies::EarlyCareerPayments::SchoolEligibility.new(current_school).eligible?,
      !Policies::LevellingUpPremiumPayments::SchoolEligibility.new(current_school).eligible?
    ].all?
  end

  def dqt_data_ineligible?
    logged_in_with_tid && qualifications_details_check && [
      itt_academic_year == AcademicYear.new,
      bad_itt_year_for_ecp?,
      bad_itt_subject_for_ecp?,
      no_ecp_subjects_that_itt_year?,
      lack_both_valid_itt_subject_and_degree?,
      trainee_teaching_lacking_both_valid_itt_subject_and_degree?
    ].any?
  end

  def ecp_only_teacher_with_ineligible_itt_year?
    [
      itt_academic_year == AcademicYear.new,
      school_eligible_for_ecp_but_not_lup?
    ].all?
  end

  def teacher_with_ineligible_itt_year?
    [
      itt_academic_year == AcademicYear.new,
      Policies::LevellingUpPremiumPayments::SchoolEligibility.new(current_school).eligible?
    ].all?
  end

  def generic?
    [
      has_entire_term_contract == false,
      employed_directly == false,
      subject_to_formal_performance_action,
      subject_to_disciplinary_action
    ].any?
  end

  def ecp_only_trainee_teacher?
    [
      !Policies::LevellingUpPremiumPayments::SchoolEligibility.new(current_school).eligible?,
      nqt_in_academic_year_after_itt == false
    ].all?
  end

  def trainee_teaching_lacking_both_valid_itt_subject_and_degree?
    [
      Policies::LevellingUpPremiumPayments::SchoolEligibility.new(current_school).eligible?,
      nqt_in_academic_year_after_itt == false,
      lack_both_valid_itt_subject_and_degree?
    ].all?
  end

  def lack_both_valid_itt_subject_and_degree?
    [
      subject_invalid_for_ecp?,
      eligible_degree_subject == false
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
    if use_claim?
      eligibility = current_claim.for_policy(policy).eligibility
      teaching_before = eligibility.teaching_subject_now
      eligible_with_sufficient_teaching = nil

      # check it and put it back
      eligibility.transaction do
        eligibility.update(teaching_subject_now: true)
        eligible_with_sufficient_teaching = eligibility.status.in?([:eligible_now, :eligible_later])
        eligibility.update(teaching_subject_now: teaching_before)
      end

      eligible_with_sufficient_teaching
    else
      checker = policy::PolicyEligibilityChecker.new(journey_session: journey_session.dup)
      checker.journey_session.answers.teaching_subject_now = true
      checker.status.in?([:eligible_now, :eligible_later])
    end
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
    !eligible_itt_subject&.to_sym&.in?(ecp_subject_options)
  end

  def policy_year
    raise "nil academic year" if policies.any? { |policy| Journeys.for_policy(policy).configuration.current_academic_year.nil? }
    raise "none academic year" if policies.any? { |policy| Journeys.for_policy(policy).configuration.current_academic_year == AcademicYear.new }

    policy_year_values_set = policies.collect { |policy| Journeys.for_policy(policy).configuration.current_academic_year }.to_set

    if policy_year_values_set.one?
      policy_year_values_set.first
    elsif policy_year_values_set.many?
      raise "Have more than one policy year in the same journey"
    else
      raise "Have no policy year for the journey"
    end
  end

  def policies
    Journeys.for_routing_name(journey_session.journey)::POLICIES
  end

  def ecp_subject_options
    JourneySubjectEligibilityChecker
      .new(claim_year: policy_year, itt_year: itt_academic_year)
      .current_and_future_subject_symbols(Policies::EarlyCareerPayments)
  end

  def bad_itt_year_for_ecp?
    [
      ecp_subject_options.one?,
      subject_invalid_for_ecp?,
      school_eligible_for_ecp_but_not_lup?
    ].all?
  end

  def school_eligible_for_ecp_but_not_lup?
    Policies::EarlyCareerPayments::SchoolEligibility.new(current_school).eligible? && !Policies::LevellingUpPremiumPayments::SchoolEligibility.new(current_school).eligible?
  end

  def bad_itt_subject_for_ecp?
    [
      ecp_subject_options.many?,
      subject_invalid_for_ecp?,
      school_eligible_for_ecp_but_not_lup?
    ].all?
  end

  def no_ecp_subjects_that_itt_year?
    [
      ecp_subject_options.none?,
      school_eligible_for_ecp_but_not_lup?
    ].all?
  end

  def trainee_teacher_last_policy_year?
    [
      nqt_in_academic_year_after_itt == false,
      academic_year >= AcademicYear.new(Policies::LevellingUpPremiumPayments::Eligibility::LAST_POLICY_YEAR),
      academic_year >= AcademicYear.new(Policies::EarlyCareerPayments::Eligibility::LAST_POLICY_YEAR)
    ].all?
  end
end
