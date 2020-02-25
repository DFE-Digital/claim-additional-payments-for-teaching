module MathsAndPhysics
  # Used to display the information a claim checker needs to check to either
  # approve or reject a claim
  #
  # Note this presenter is only intented for use with eligible claims and
  # therefor makes certain assumptions about the claim and eligibility.
  # Specifically it assumes the QTS question was answered with
  # :on_or_after_cut_off_date.
  class AdminChecksPresenter
    include Admin::PresenterMethods

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def qualifications
      [].tap do |a|
        a << ["Award year", qts_award_year_answer]
        a << ["ITT subject", itt_subject]
        a << ["Maths or Physics degree", maths_or_physics_degree] if eligibility.has_uk_maths_or_physics_degree.present?
      end
    end

    def employment
      [
        [I18n.t("admin.current_school"), display_school(eligibility.current_school)],
      ]
    end

    private

    def eligibility
      claim.eligibility
    end

    def itt_subject
      (eligibility.initial_teacher_training_subject_specialism || eligibility.initial_teacher_training_subject).humanize
    end

    def maths_or_physics_degree
      if eligibility.has_uk_maths_or_physics_degree == "yes"
        "UK Maths or Physics degree"
      elsif eligibility.has_uk_maths_or_physics_degree == "has_non_uk"
        "Non-UK Maths or Physics degree"
      end
    end

    def qts_award_year_answer
      qts_cut_off_for_claim = MathsAndPhysics.first_eligible_qts_award_year(claim.academic_year)
      I18n.t("answers.qts_award_years.on_or_after_cut_off_date", year: qts_cut_off_for_claim.to_s(:long))
    end
  end
end
