require "rails_helper"

RSpec.describe Policies::EarlyCareerPayments::EligibilityAdminAnswersPresenter, type: :model do
  let(:claim) { build(:claim, :submittable, policy: Policies::EarlyCareerPayments, academic_year: "2021/2022") }

  subject(:presenter) { described_class.new(claim.eligibility) }

  describe "#answers" do
    it "returns an array of questions and answers for displaying to service operator" do
      expected_answers = [
        [I18n.t("early_career_payments.admin.nqt_in_academic_year_after_itt"), "Yes"],
        [I18n.t("early_career_payments.admin.induction_completed"), "Yes"],
        [I18n.t("early_career_payments.admin.employed_as_supply_teacher"), "No"]
      ]

      expect(presenter.answers).to eq expected_answers
    end
  end
end
