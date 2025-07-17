require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::TeachingHoursPerWeekForm, type: :model do
  let(:fe_provider) do
    create(:school, :fe_eligible, name: "Springfield College")
  end

  let(:user) { create(:dfe_signin_user) }

  let(:claim) { create(:claim, :further_education) }

  let(:params) { {} }

  subject(:form) do
    described_class.new(
      claim: claim,
      user: user,
      params: params
    )
  end

  describe "validations" do
    context "when submission" do
      it do
        is_expected.not_to(
          allow_value(nil).for(:provider_verification_teaching_hours_per_week)
        )
      end

      it do
        is_expected.to(
          allow_value("more_than_12").for(:provider_verification_teaching_hours_per_week)
        )
      end

      it do
        is_expected.to(
          allow_value("between_2_5_and_12").for(:provider_verification_teaching_hours_per_week)
        )
      end

      it do
        is_expected.to(
          allow_value("less_than_2_5").for(:provider_verification_teaching_hours_per_week)
        )
      end

      it do
        is_expected.not_to(
          allow_value("invalid_option").for(:provider_verification_teaching_hours_per_week)
        )
      end
    end

    context "when saving progress" do
      before do
        allow(form).to receive(:save_and_exit?).and_return(true)
      end

      it do
        is_expected.to(
          allow_value(nil).for(:provider_verification_teaching_hours_per_week)
        )
      end
    end
  end

  describe "#incomplete?" do
    context "when form is valid" do
      let(:params) do
        {
          provider_verification_teaching_hours_per_week: "more_than_12"
        }
      end

      it "returns false" do
        expect(form.incomplete?).to be(false)
      end
    end

    context "when form is invalid" do
      let(:params) { {} }

      it "returns true" do
        expect(form.incomplete?).to be(true)
      end
    end
  end

  describe "#save" do
    context "when form is valid" do
      let(:params) do
        {
          provider_verification_teaching_hours_per_week: "more_than_12"
        }
      end

      it "updates the claim eligibility and returns true" do
        expect(form.save).to be(true)

        claim.eligibility.reload

        expect(
          claim.eligibility.provider_verification_teaching_hours_per_week
        ).to eq("more_than_12")
      end
    end

    context "when form is invalid" do
      let(:params) { {} }

      it "returns false" do
        expect(form.save).to be(false)
      end
    end
  end
end
