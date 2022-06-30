require "rails_helper"

RSpec.describe EarlyCareerPayments::EligibilityAnswersPresenter, type: :model do
  before do
    @ecp_policy_date = PolicyConfiguration.for(EarlyCareerPayments).current_academic_year
    PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: academic_year)
  end

  after do
    PolicyConfiguration.for(EarlyCareerPayments).update(current_academic_year: @ecp_policy_date)
  end
  let(:academic_year) { AcademicYear.new(2021) }

  let(:eligibility_attributes) do
    {
      current_school: schools(:penistone_grammar_school),
      nqt_in_academic_year_after_itt: true,
      employed_as_supply_teacher: false,
      subject_to_formal_performance_action: false,
      subject_to_disciplinary_action: false,
      qualification: :postgraduate_itt,
      eligible_itt_subject: :chemistry,
      teaching_subject_now: true,
      itt_academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2019))
    }
  end
  let(:eligibility) { claim.eligibility }
  let(:claim) { build(:claim, academic_year: academic_year, eligibility: build(:early_career_payments_eligibility, eligibility_attributes)) }

  subject(:presenter) { described_class.new(eligibility) }

  it "returns an array of questions and answers to be presented to the user for checking" do
    expected_answers = [
      [I18n.t("early_career_payments.questions.current_school_search"), "Penistone Grammar School", "current-school"],
      [I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"), "Yes", "nqt-in-academic-year-after-itt"],
      [I18n.t("early_career_payments.questions.employed_as_supply_teacher"), "No", "supply-teacher"],
      [I18n.t("early_career_payments.questions.formal_performance_action"), "No", "poor-performance"],
      [I18n.t("early_career_payments.questions.disciplinary_action"), "No", "poor-performance"],
      [
        I18n.t("early_career_payments.questions.qualification.heading"),
        "Postgraduate initial teacher training (ITT)",
        "qualification"
      ],
      [
        I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{eligibility.qualification}"),
        "2019 - 2020",
        "itt-year"
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
      ]
    ]

    expect(presenter.answers).to eq(expected_answers)
  end

  context "when employed as a supply teacher" do
    let(:eligibility_attributes) do
      {
        current_school: schools(:penistone_grammar_school),
        nqt_in_academic_year_after_itt: true,
        employed_as_supply_teacher: true,
        has_entire_term_contract: true,
        employed_directly: true,
        subject_to_formal_performance_action: false,
        subject_to_disciplinary_action: false,
        qualification: :undergraduate_itt,
        eligible_itt_subject: :foreign_languages,
        teaching_subject_now: true,
        itt_academic_year: AcademicYear.new(2018)
      }
    end

    it "includes supply teacher questions" do
      expected_answers = [
        [I18n.t("early_career_payments.questions.current_school_search"), "Penistone Grammar School", "current-school"],
        [I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt.heading"), "Yes", "nqt-in-academic-year-after-itt"],
        [I18n.t("early_career_payments.questions.employed_as_supply_teacher"), "Yes", "supply-teacher"],
        [I18n.t("early_career_payments.questions.has_entire_term_contract"), "Yes", "entire-term-contract"],
        [I18n.t("early_career_payments.questions.employed_directly"), "Yes", "employed-directly"],
        [I18n.t("early_career_payments.questions.formal_performance_action"), "No", "poor-performance"],
        [I18n.t("early_career_payments.questions.disciplinary_action"), "No", "poor-performance"],
        [
          I18n.t("early_career_payments.questions.qualification.heading"),
          "Undergraduate initial teacher training (ITT)",
          "qualification"
        ],
        [
          I18n.t("early_career_payments.questions.itt_academic_year.qualification.#{eligibility.qualification}"),
          "2018 - 2019",
          "itt-year"
        ],
        [
          I18n.t("early_career_payments.questions.eligible_itt_subject", qualification: eligibility.qualification_name),
          "Languages",
          "eligible-itt-subject"
        ],
        [
          I18n.t("early_career_payments.questions.teaching_subject_now", eligible_itt_subject: eligibility.eligible_itt_subject),
          "Yes",
          "teaching-subject-now"
        ]
      ]

      expect(presenter.answers).to eq(expected_answers)
    end
  end
end
