require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::EligibilityAdminAnswersPresenter, type: :model do
  let(:eligibility) { claim.eligibility }
  let(:claim) do
    build(
      :claim,
      :submittable,
      policy: Policies::TargetedRetentionIncentivePayments,
      academic_year: "2021/2022"
    )
  end

  subject(:presenter) { described_class.new(eligibility) }

  describe "#answers" do
    it "returns an array of questions and answers for displaying to service operator" do
      expected_answers = [
        [I18n.t("targeted_retention_incentive_payments.admin.nqt_in_academic_year_after_itt"), "Yes"],
        [I18n.t("targeted_retention_incentive_payments.admin.employed_as_supply_teacher"), "No"],
        [I18n.t("targeted_retention_incentive_payments.admin.degree_in_an_eligible_subject"), "N/A"]
      ]

      expect(presenter.answers).to eq expected_answers
    end
  end
end
