require "rails_helper"

RSpec.describe Policies::InternationalRelocationPayments::EligibilityAdminAnswersPresenter, type: :model do
  let(:claim) { build(:claim, :submittable, policy: Policies::InternationalRelocationPayments, academic_year: "2021/2022") }

  subject(:presenter) { described_class.new(claim.eligibility) }

  describe "#answers" do
    it "returns an array of questions and answers for displaying to service operator" do
      expect(presenter.answers).to eq [[I18n.t("admin.current_school"), presenter.display_school(claim.eligibility.current_school)]]
    end
  end
end
