class QualificationDetailsForm < Form
  attribute :qualifications_details_check, :boolean

  validates :qualifications_details_check,
    inclusion: {
      in: [true, false],
      message: "Select yes if your qualification details are correct"
    }

  def initialize(claim:, journey:, params:)
    super

    self.qualifications_details_check = permitted_params.fetch(
      :qualifications_details_check,
      claim.qualifications_details_check
    )
  end

  def save
    return false unless valid?

    claim.assign_attributes(
      qualifications_details_check: qualifications_details_check
    )

    if qualifications_details_check
      # Teacher has confirmed the details in the dqt record are correct, update
      # the eligibility with these details
      claim.claims.each { |c| set_qualifications_from_dqt_record(c.eligibility) }
    else
      # Teacher has said the details don't match what they expected so
      # nullify them
      claim.claims.each { |c| set_nil_qualifications(c.eligibility) }
    end

    claim.save!
  end

  private

  def set_qualifications_from_dqt_record(eligibility)
    dqt_record = eligibility.claim.dqt_teacher_record

    case eligibility
    when Policies::EarlyCareerPayments::Eligibility
      eligibility.assign_attributes(
        itt_academic_year: itt_academic_year(dqt_record, eligibility),
        eligible_itt_subject: eligible_itt_subject(dqt_record, eligibility),
        qualification: qualification(dqt_record, eligibility)
      )
    when Policies::LevellingUpPremiumPayments::Eligibility
      eligibility.assign_attributes(
        itt_academic_year: itt_academic_year(dqt_record, eligibility),
        eligible_itt_subject: eligible_itt_subject(dqt_record, eligibility),
        qualification: qualification(dqt_record, eligibility),
        eligible_degree_subject: eligible_degree_subject(dqt_record, eligibility)
      )
    when Policies::StudentLoans::Eligibility
      eligibility.qts_award_year = qts_award_year(dqt_record, eligibility)
    else
      fail "Unknown eligibility type #{claim.eligibility}"
    end
  end

  def set_nil_qualifications(eligibility)
    case eligibility
    when Policies::EarlyCareerPayments::Eligibility
      eligibility.assign_attributes(
        itt_academic_year: nil,
        eligible_itt_subject: nil,
        qualification: nil
      )
    when Policies::LevellingUpPremiumPayments::Eligibility
      eligibility.assign_attributes(
        itt_academic_year: nil,
        eligible_itt_subject: nil,
        qualification: nil,
        eligible_degree_subject: nil
      )
    when Policies::StudentLoans::Eligibility
      eligibility.qts_award_year = nil
    else
      fail "Unknown eligibility type #{claim.eligibility}"
    end
  end

  def itt_academic_year(dqt_teacher_record, eligibility)
    if dqt_teacher_record&.itt_academic_year_for_claim
      dqt_teacher_record.itt_academic_year_for_claim
    else
      eligibility.itt_academic_year
    end
  end

  def eligible_itt_subject(dqt_teacher_record, eligibility)
    if dqt_teacher_record&.eligible_itt_subject_for_claim
      dqt_teacher_record.eligible_itt_subject_for_claim
    else
      eligibility.eligible_itt_subject
    end
  end

  def qualification(dqt_teacher_record, eligibility)
    if dqt_teacher_record&.route_into_teaching
      dqt_teacher_record.route_into_teaching
    else
      eligibility.qualification
    end
  end

  def eligible_degree_subject(dqt_teacher_record, eligibility)
    if dqt_teacher_record&.eligible_degree_code?
      dqt_teacher_record.eligible_degree_code?
    else
      eligibility.eligible_degree_subject
    end
  end

  def qts_award_year(dqt_teacher_record, eligibility)
    return nil unless dqt_teacher_record&.qts_award_date

    if dqt_teacher_record.eligible_qts_award_date?
      :on_or_after_cut_off_date
    else
      :before_cut_off_date
    end
  end
end
