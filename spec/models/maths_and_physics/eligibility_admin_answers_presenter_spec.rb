require "rails_helper"

RSpec.describe MathsAndPhysics::EligibilityAdminAnswersPresenter, type: :model do
  let(:eligibility) { claim.eligibility }
  let(:claim) do
    build(:claim,
      policy: MathsAndPhysics,
      academic_year: "2019/2020",
      eligibility: build(:maths_and_physics_eligibility,
        :eligible,
        initial_teacher_training_subject_specialism: :not_sure,
        has_uk_maths_or_physics_degree: "has_non_uk",
        employed_as_supply_teacher: true,
        has_entire_term_contract: true,
        employed_directly: true,
        subject_to_disciplinary_action: true,
        subject_to_formal_performance_action: true))
  end
  subject(:presenter) { described_class.new(eligibility) }

  describe "#answers" do
    it "returns an array of questions and answers for displaying to service operator" do
      expected_answers = [
        [I18n.t("maths_and_physics.admin.teaching_maths_or_physics"), "Yes"],
        [I18n.t("admin.current_school"), presenter.display_school(eligibility.current_school)],
        [I18n.t("maths_and_physics.admin.initial_teacher_training_subject"), "Maths"],
        [I18n.t("maths_and_physics.admin.initial_teacher_training_subject_specialism"), "I’m not sure"],
        [I18n.t("maths_and_physics.admin.has_uk_maths_or_physics_degree"), "I have a non-UK degree in Maths or Physics"],
        [I18n.t("admin.qts_award_year"), "In or after the academic year 2014 to 2015"],
        [I18n.t("maths_and_physics.admin.employed_as_supply_teacher"), "Yes"],
        [I18n.t("maths_and_physics.admin.has_entire_term_contract"), "Yes"],
        [I18n.t("maths_and_physics.admin.employed_directly"), "Yes, I’m employed by my school"],
        [I18n.t("maths_and_physics.admin.disciplinary_action"), "Yes"],
        [I18n.t("maths_and_physics.admin.formal_performance_action"), "Yes"]
      ]

      expect(presenter.answers).to eq expected_answers
    end

    it "changes the answer for the QTS question based on the answer academic year the claim was made" do
      claim.academic_year = "2021/2022"

      expected_qts_answer = presenter.answers[5][1]
      expect(expected_qts_answer).to eq("In or after the academic year 2016 to 2017")
    end

    it "excludes questions skipped from the flow" do
      eligibility.initial_teacher_training_subject_specialism = :physics
      eligibility.has_uk_maths_or_physics_degree = nil
      expect(presenter.answers).to include([I18n.t("maths_and_physics.admin.initial_teacher_training_subject_specialism"), "Physics"])
      expect(presenter.answers).not_to include([I18n.t("maths_and_physics.admin.has_uk_maths_or_physics_degree"), "I have a non-UK degree in Maths or Physics"])

      eligibility.employed_as_supply_teacher = false
      eligibility.has_entire_term_contract = nil
      eligibility.employed_directly = nil
      expect(presenter.answers).to include([I18n.t("maths_and_physics.admin.employed_as_supply_teacher"), "No"])
      expect(presenter.answers).not_to include([I18n.t("maths_and_physics.admin.has_entire_term_contract"), "Yes"])
      expect(presenter.answers).not_to include([I18n.t("maths_and_physics.admin.employed_directly"), "Yes, I’m employed by my school"])
    end
  end
end
