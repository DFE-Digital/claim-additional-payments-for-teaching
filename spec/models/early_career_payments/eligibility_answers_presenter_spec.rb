require "rails_helper"

RSpec.describe EarlyCareerPayments::EligibilityAnswersPresenter do
  let(:eligibility_attributes) do
    {
      nqt_in_academic_year_after_itt: true,
      employed_as_supply_teacher: false
    }
  end
  let(:eligibility) { claim.eligibility }
  let(:claim) { build(:claim, eligibility: build(:early_career_payments_eligibility, eligibility_attributes)) }

  subject(:presenter) { described_class.new(eligibility) }

  it "returns an array of questions and answers to be presented to the user for checking" do
    expected_answers = [
      [I18n.t("early_career_payments.questions.nqt_in_academic_year_after_itt"), "Yes", "nqt-in-academic-year-after-itt"],
      [I18n.t("early_career_payments.questions.employed_as_supply_teacher"), "No", "supply-teacher"]
    ]

    expect(presenter.answers).to eq(expected_answers)
  end
end
