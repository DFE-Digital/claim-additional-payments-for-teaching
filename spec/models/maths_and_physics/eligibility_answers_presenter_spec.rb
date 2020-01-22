require "rails_helper"

RSpec.describe MathsAndPhysics::EligibilityAnswersPresenter do
  let(:eligibility) do
    build(:maths_and_physics_eligibility,
      teaching_maths_or_physics: true,
      current_school: schools(:penistone_grammar_school),
      initial_teacher_training_subject: :maths,
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
      [I18n.t("maths_and_physics.questions.initial_teacher_training_subject"), "Maths", "initial-teacher-training-subject"],
      [I18n.t("questions.qts_award_year"), "In or after the academic year 2014 to 2015", "qts-year"],
      [I18n.t("maths_and_physics.questions.employed_as_supply_teacher"), "No", "supply-teacher"],
      [I18n.t("maths_and_physics.questions.disciplinary_action"), "No", "disciplinary-action"],
      [I18n.t("maths_and_physics.questions.formal_performance_action"), "No", "formal-performance-action"],
    ]

    expect(presenter.answers).to eq(expected_answers)
  end

  context "initial teacher training subject not in a science" do
    let(:eligibility) do
      build(:maths_and_physics_eligibility,
        teaching_maths_or_physics: true,
        current_school: schools(:penistone_grammar_school),
        initial_teacher_training_subject: :none_of_the_subjects,
        has_uk_maths_or_physics_degree: "has_non_uk",
        qts_award_year: "on_or_after_september_2014",
        employed_as_supply_teacher: false,
        subject_to_disciplinary_action: false,
        subject_to_formal_performance_action: false)
    end

    it "includes the specialism and degree in the questions and answers" do
      expected_answers = [
        [I18n.t("maths_and_physics.questions.teaching_maths_or_physics"), "Yes", "teaching-maths-or-physics"],
        [I18n.t("questions.current_school"), "Penistone Grammar School", "current-school"],
        [I18n.t("maths_and_physics.questions.initial_teacher_training_subject"), "None of these subjects", "initial-teacher-training-subject"],
        [I18n.t("maths_and_physics.questions.has_uk_maths_or_physics_degree"), "I have a non-UK degree in Maths or Physics", "has-uk-maths-or-physics-degree"],
        [I18n.t("questions.qts_award_year"), "In or after the academic year 2014 to 2015", "qts-year"],
        [I18n.t("maths_and_physics.questions.employed_as_supply_teacher"), "No", "supply-teacher"],
        [I18n.t("maths_and_physics.questions.disciplinary_action"), "No", "disciplinary-action"],
        [I18n.t("maths_and_physics.questions.formal_performance_action"), "No", "formal-performance-action"],
      ]

      expect(presenter.answers).to eq(expected_answers)
    end
  end

  context "initial teacher training subject specialism and degree questions answered" do
    let(:eligibility) do
      build(:maths_and_physics_eligibility,
        teaching_maths_or_physics: true,
        current_school: schools(:penistone_grammar_school),
        initial_teacher_training_subject: :science,
        initial_teacher_training_subject_specialism: :not_sure,
        has_uk_maths_or_physics_degree: "has_non_uk",
        qts_award_year: "on_or_after_september_2014",
        employed_as_supply_teacher: false,
        subject_to_disciplinary_action: false,
        subject_to_formal_performance_action: false)
    end

    it "includes the specialism and degree in the questions and answers" do
      expected_answers = [
        [I18n.t("maths_and_physics.questions.teaching_maths_or_physics"), "Yes", "teaching-maths-or-physics"],
        [I18n.t("questions.current_school"), "Penistone Grammar School", "current-school"],
        [I18n.t("maths_and_physics.questions.initial_teacher_training_subject"), "Science (physics, biology and chemistry)", "initial-teacher-training-subject"],
        [I18n.t("maths_and_physics.questions.initial_teacher_training_subject_specialism"), "I’m not sure", "initial-teacher-training-subject-specialism"],
        [I18n.t("maths_and_physics.questions.has_uk_maths_or_physics_degree"), "I have a non-UK degree in Maths or Physics", "has-uk-maths-or-physics-degree"],
        [I18n.t("questions.qts_award_year"), "In or after the academic year 2014 to 2015", "qts-year"],
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
        initial_teacher_training_subject: :physics,
        initial_teacher_training_subject_specialism: :physics,
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
        [I18n.t("maths_and_physics.questions.initial_teacher_training_subject"), "Physics", "initial-teacher-training-subject"],
        [I18n.t("maths_and_physics.questions.initial_teacher_training_subject_specialism"), "Physics", "initial-teacher-training-subject-specialism"],
        [I18n.t("questions.qts_award_year"), "In or after the academic year 2014 to 2015", "qts-year"],
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
