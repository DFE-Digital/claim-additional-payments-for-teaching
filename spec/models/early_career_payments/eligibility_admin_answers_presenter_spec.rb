require "rails_helper"

RSpec.describe EarlyCareerPayments::EligibilityAdminAnswersPresenter, type: :model do
  let(:school) { schools(:penistone_grammar_school) }
  let(:eligibility) { claim.eligibility }
  let(:claim) do
    build(
      :claim,
      academic_year: "2021/2022",
      eligibility: build(:early_career_payments_eligibility, :eligible)
    )
  end

  subject(:presenter) { described_class.new(eligibility) }

  describe "#answers" do
    it "returns an array of questions and answers for displaying to service operator" do
      expected_answers = [
        [I18n.t("early_career_payments.admin.nqt_in_academic_year_after_itt"), "Yes"],
        [I18n.t("early_career_payments.admin.employed_as_supply_teacher"), "No"]
      ]

      expect(presenter.answers).to eq expected_answers
    end
  end
end
