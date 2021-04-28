require "rails_helper"

RSpec.describe EarlyCareerPayments::EligibilityAnswersPresenter do
  let(:eligibility_attributes) do
    {
      nqt_in_academic_year_after_itt: true,
      employed_as_supply_teacher: false,
      subject_to_disciplinary_action: false,
      pgitt_or_ugitt_course: :postgraduate,
      eligible_itt_subject: :chemistry
    }
  end
  let(:eligibility) { claim.eligibility }
  let(:claim) { build(:claim, eligibility: build(:early_career_payments_eligibility, eligibility_attributes)) }

  subject(:presenter) { described_class.new(eligibility) }

  it "returns an array of questions and answers to be presented to the user for checking" do
    expected_answers = [
      [I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"), "Yes", "nqt-in-academic-year-after-itt"],
      [I18n.t("early_career_payments.questions.employed_as_supply_teacher"), "No", "supply-teacher"],
      [I18n.t("early_career_payments.questions.disciplinary_action"), "No", "disciplinary-action"],
      [I18n.t("early_career_payments.questions.postgraduate_itt_or_undergraduate_itt_course"), "Postgraduate", "postgraduate-itt-or-undergraduate-itt-course"],
      [
        I18n.t("early_career_payments.questions.eligible_itt_subject", ug_or_pg: eligibility.pgitt_or_ugitt_course),
        "Chemistry",
        "eligible-itt-subject"
      ]
    ]

    expect(presenter.answers).to eq(expected_answers)
  end

  context "when employed as a supply teacher" do
    let(:eligibility_attributes) do
      {
        nqt_in_academic_year_after_itt: true,
        employed_as_supply_teacher: true,
        has_entire_term_contract: true,
        employed_directly: true,
        subject_to_disciplinary_action: false,
        pgitt_or_ugitt_course: :postgraduate,
        eligible_itt_subject: :modern_foreign_languages
      }
    end

    it "includes supply teacher questions" do
      expected_answers = [
        [I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"), "Yes", "nqt-in-academic-year-after-itt"],
        [I18n.t("early_career_payments.questions.employed_as_supply_teacher"), "Yes", "supply-teacher"],
        [I18n.t("early_career_payments.questions.has_entire_term_contract"), "Yes", "entire-term-contract"],
        [I18n.t("early_career_payments.questions.employed_directly"), "Yes", "employed-directly"],
        [I18n.t("early_career_payments.questions.disciplinary_action"), "No", "disciplinary-action"],
        [
          I18n.t("early_career_payments.questions.postgraduate_itt_or_undergraduate_itt_course"),
          "Postgraduate",
          "postgraduate-itt-or-undergraduate-itt-course"
        ],
        [
          I18n.t("early_career_payments.questions.eligible_itt_subject", ug_or_pg: eligibility.pgitt_or_ugitt_course),
          "Modern foreign languages",
          "eligible-itt-subject"
        ]
      ]

      expect(presenter.answers).to eq(expected_answers)
    end
  end
end
