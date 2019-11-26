require "rails_helper"

RSpec.describe MathsAndPhysics::EligibilityAnswersPresenter do
  let(:eligibility) do
    build(:maths_and_physics_eligibility,
      teaching_maths_or_physics: true,
      current_school: schools(:penistone_grammar_school),
      initial_teacher_training_specialised_in_maths_or_physics: true,
      qts_award_year: "on_or_after_september_2014",
      employed_as_supply_teacher: false,
      subject_to_disciplinary_action: false,
      subject_to_formal_performance_action: false)
  end
  subject(:presenter) { described_class.new(eligibility) }

  it "returns an array of questions and answers to be presented to the user for checking" do
    expected_answers = [
      [I18n.t("maths_and_physics.questions.teaching_maths_or_physics"), "Yes", "teaching-maths-or-physics"],
      [I18n.t("questions.current_school"), "Penistone Grammar School", "current-school"],
      [I18n.t("maths_and_physics.questions.initial_teacher_training_specialised_in_maths_or_physics"), "Yes", "initial-teacher-training-specialised-in-maths-or-physics"],
      [I18n.t("questions.qts_award_year"), "On or after 1 September 2014", "qts-year"],
      [I18n.t("maths_and_physics.questions.employed_as_supply_teacher"), "No", "supply-teacher"],
      [I18n.t("maths_and_physics.questions.disciplinary_action"), "No", "disciplinary-action"],
      [I18n.t("maths_and_physics.questions.formal_performance_action"), "No", "formal-performance-action"],
    ]

    expect(presenter.answers).to eq(expected_answers)
  end

  context "initial teacher training didn't specialise in maths or physics" do
    let(:eligibility) do
      build(:maths_and_physics_eligibility,
        teaching_maths_or_physics: true,
        current_school: schools(:penistone_grammar_school),
        initial_teacher_training_specialised_in_maths_or_physics: false,
        has_uk_maths_or_physics_degree: "has_non_uk",
        qts_award_year: "on_or_after_september_2014",
        employed_as_supply_teacher: false,
        subject_to_disciplinary_action: false,
        subject_to_formal_performance_action: false)
    end

    it "includes degree question" do
      expected_answers = [
        [I18n.t("maths_and_physics.questions.teaching_maths_or_physics"), "Yes", "teaching-maths-or-physics"],
        [I18n.t("questions.current_school"), "Penistone Grammar School", "current-school"],
        [I18n.t("maths_and_physics.questions.initial_teacher_training_specialised_in_maths_or_physics"), "No", "initial-teacher-training-specialised-in-maths-or-physics"],
        [I18n.t("maths_and_physics.questions.has_uk_maths_or_physics_degree"), "I have a non-UK degree in Maths or Physics", "has-uk-maths-or-physics-degree"],
        [I18n.t("questions.qts_award_year"), "On or after 1 September 2014", "qts-year"],
        [I18n.t("maths_and_physics.questions.employed_as_supply_teacher"), "No", "supply-teacher"],
        [I18n.t("maths_and_physics.questions.disciplinary_action"), "No", "disciplinary-action"],
        [I18n.t("maths_and_physics.questions.formal_performance_action"), "No", "formal-performance-action"],
      ]

      expect(presenter.answers).to eq(expected_answers)
    end
  end

  context "employed as supply teacher" do
    let(:eligibility) do
      build(:maths_and_physics_eligibility,
        teaching_maths_or_physics: true,
        current_school: schools(:penistone_grammar_school),
        initial_teacher_training_specialised_in_maths_or_physics: true,
        qts_award_year: "on_or_after_september_2014",
        employed_as_supply_teacher: true,
        has_entire_term_contract: true,
        employed_directly: true,
        subject_to_disciplinary_action: false,
        subject_to_formal_performance_action: false)
    end

    it "includes supply teacher questions" do
      expected_answers = [
        [I18n.t("maths_and_physics.questions.teaching_maths_or_physics"), "Yes", "teaching-maths-or-physics"],
        [I18n.t("questions.current_school"), "Penistone Grammar School", "current-school"],
        [I18n.t("maths_and_physics.questions.initial_teacher_training_specialised_in_maths_or_physics"), "Yes", "initial-teacher-training-specialised-in-maths-or-physics"],
        [I18n.t("questions.qts_award_year"), "On or after 1 September 2014", "qts-year"],
        [I18n.t("maths_and_physics.questions.employed_as_supply_teacher"), "Yes", "supply-teacher"],
        [I18n.t("maths_and_physics.questions.has_entire_term_contract"), "Yes", "entire-term-contract"],
        [I18n.t("maths_and_physics.questions.employed_directly"), "Yes, I’m employed by my school", "employed-directly"],
        [I18n.t("maths_and_physics.questions.disciplinary_action"), "No", "disciplinary-action"],
        [I18n.t("maths_and_physics.questions.formal_performance_action"), "No", "formal-performance-action"],
      ]

      expect(presenter.answers).to eq(expected_answers)
    end
  end
end
