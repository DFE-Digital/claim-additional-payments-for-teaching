require "rails_helper"

RSpec.describe EarlyCareerPayments::EligibilityAnswersPresenter, type: :model do
  let(:eligibility_attributes) do
    {
      nqt_in_academic_year_after_itt: true,
      current_school: schools(:penistone_grammar_school),
      employed_as_supply_teacher: false,
      subject_to_formal_performance_action: false,
      subject_to_disciplinary_action: false,
      qualification: :postgraduate_itt,
      eligible_itt_subject: :chemistry,
      teaching_subject_now: true,
      itt_academic_year: "2019_2020"
    }
  end
  let(:eligibility) { claim.eligibility }
  let(:claim) { build(:claim, eligibility: build(:early_career_payments_eligibility, eligibility_attributes)) }

  subject(:presenter) { described_class.new(eligibility) }

  it "returns an array of questions and answers to be presented to the user for checking" do
    expected_answers = [
      [I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"), "Yes", "nqt-in-academic-year-after-itt"],
      [I18n.t("questions.current_school"), "Penistone Grammar School", "current-school"],
      [I18n.t("early_career_payments.questions.employed_as_supply_teacher"), "No", "supply-teacher"],
      [I18n.t("early_career_payments.questions.formal_performance_action"), "No", "formal-performance-action"],
      [I18n.t("early_career_payments.questions.disciplinary_action"), "No", "disciplinary-action"],
      [
        I18n.t("early_career_payments.questions.qualification.heading"),
        "Postgraduate ITT",
        "qualification"
      ],
      [
        I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: eligibility.qualification_name),
        "Chemistry",
        "eligible-itt-subject"
      ],
      [
        I18n.t("early_career_payments.questions.teaching_subject_now", eligible_itt_subject: eligibility.eligible_itt_subject),
        "Yes",
        "teaching-subject-now"
      ],
      [
        I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{eligibility.qualification}"),
        "2019 - 2020",
        "itt-year"
      ]
    ]

    expect(presenter.answers).to eq(expected_answers)
  end

  context "when employed as a supply teacher" do
    let(:eligibility_attributes) do
      {
        nqt_in_academic_year_after_itt: true,
        current_school: schools(:penistone_grammar_school),
        employed_as_supply_teacher: true,
        has_entire_term_contract: true,
        employed_directly: true,
        subject_to_formal_performance_action: false,
        subject_to_disciplinary_action: false,
        qualification: :undergraduate_itt,
        eligible_itt_subject: :foreign_languages,
        teaching_subject_now: true,
        itt_academic_year: "2018_2019"
      }
    end

    it "includes supply teacher questions" do
      expected_answers = [
        [I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"), "Yes", "nqt-in-academic-year-after-itt"],
        [I18n.t("questions.current_school"), "Penistone Grammar School", "current-school"],
        [I18n.t("early_career_payments.questions.employed_as_supply_teacher"), "Yes", "supply-teacher"],
        [I18n.t("early_career_payments.questions.has_entire_term_contract"), "Yes", "entire-term-contract"],
        [I18n.t("early_career_payments.questions.employed_directly"), "Yes", "employed-directly"],
        [I18n.t("early_career_payments.questions.formal_performance_action"), "No", "formal-performance-action"],
        [I18n.t("early_career_payments.questions.disciplinary_action"), "No", "disciplinary-action"],
        [
          I18n.t("early_career_payments.questions.qualification.heading"),
          "Undergraduate ITT",
          "qualification"
        ],
        [
          I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: eligibility.qualification_name),
          "Foreign languages",
          "eligible-itt-subject"
        ],
        [
          I18n.t("early_career_payments.questions.teaching_subject_now", eligible_itt_subject: eligibility.eligible_itt_subject),
          "Yes",
          "teaching-subject-now"
        ],
        [
          I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{eligibility.qualification}"),
          "2018 - 2019",
          "itt-year"
        ]
      ]

      expect(presenter.answers).to eq(expected_answers)
    end
  end
end
