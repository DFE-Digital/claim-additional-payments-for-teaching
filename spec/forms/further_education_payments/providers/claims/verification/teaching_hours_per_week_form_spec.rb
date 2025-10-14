require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::TeachingHoursPerWeekForm, type: :model do
  let(:fe_provider) do
    create(:school, :fe_eligible, name: "Springfield College")
  end

  let(:user) { create(:dfe_signin_user) }

  let(:claim) do
    create(
      :claim,
      :further_education,
      submitted_at: DateTime.new(2025, 5, 1, 12, 0, 0)
    )
  end

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
        is_expected.to(
          validate_inclusion_of(:provider_verification_teaching_hours_per_week)
          .in_array(
            %w[
              20_or_more_hours_per_week
              12_to_20_hours_per_week
              2_and_a_half_to_12_hours_per_week
              fewer_than_2_and_a_half_hours_per_week
            ]
          )
          .with_message(
            "Select how many hours #{form.claimant_name} was timetabled to " \
            "teach at #{form.provider_name} during the spring term"
          )
        )
      end
    end

    context "when saving progress" do
      before do
        allow(form).to receive(:save_and_exit?).and_return(true)
      end

      it do
        is_expected.to(
          validate_inclusion_of(:provider_verification_teaching_hours_per_week)
          .in_array([
            "20_or_more_hours_per_week",
            "12_to_20_hours_per_week",
            "2_and_a_half_to_12_hours_per_week",
            "fewer_than_2_and_a_half_hours_per_week",
            nil
          ])
          .with_message(
            "Select how many hours #{form.claimant_name} was timetabled to " \
            "teach at #{form.provider_name} during the spring term"
          )
        )
      end
    end
  end

  describe "#incomplete?" do
    context "when form is valid" do
      let(:params) do
        {
          provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week"
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
          provider_verification_teaching_hours_per_week: "20_or_more_hours_per_week"
        }
      end

      it "updates the claim eligibility and returns true" do
        expect(form.save).to be(true)

        claim.eligibility.reload

        expect(
          claim.eligibility.provider_verification_teaching_hours_per_week
        ).to eq("20_or_more_hours_per_week")
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
