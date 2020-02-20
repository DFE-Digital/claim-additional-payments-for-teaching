module MathsAndPhysics
  class AdminChecksPresenter
    include Admin::PresenterMethods

    attr_reader :claim

    def initialize(claim)
      @claim = claim
    end

    def qualifications
      [].tap do |a|
        a << ["Award year", I18n.t("maths_and_physics.questions.qts_award_years.#{eligibility.qts_award_year}")]
        a << ["ITT subject", (eligibility.initial_teacher_training_subject_specialism || eligibility.initial_teacher_training_subject).humanize]
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

    def maths_or_physics_degree
      if eligibility.has_uk_maths_or_physics_degree == "yes"
        "UK Maths or Physics degree"
      elsif eligibility.has_uk_maths_or_physics_degree == "has_non_uk"
        "Non-UK Maths or Physics degree"
      end
    end
  end
end
