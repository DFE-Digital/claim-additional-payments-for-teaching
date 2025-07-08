require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::RoleAndExperienceForm, type: :model do
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
    it do
      is_expected.not_to(allow_value(nil).for(
        :provider_verification_role_and_experience_section_completed
      ))
    end

    context "when submission" do
      before do
        form.provider_verification_role_and_experience_section_completed = true
      end

      it do
        is_expected.not_to(
          allow_value(nil).for(:provider_verification_teaching_responsibilities)
        )
      end

      it do
        is_expected.not_to(
          allow_value(nil).for(:provider_verification_in_first_five_years)
        )
      end

      it do
        is_expected.to(
          validate_inclusion_of(:provider_verification_teaching_qualification)
            .in_array(%w[yes not_yet no_but_planned no_not_planned])
        )
      end

      it do
        is_expected.to(
          validate_inclusion_of(:provider_verification_contract_type)
            .in_array(%w[permanent fixed_term variable_hours])
        )
      end
    end

    context "when saving progress" do
      before do
        form.provider_verification_role_and_experience_section_completed = false
      end

      it do
        is_expected.to(
          allow_value(nil).for(:provider_verification_teaching_responsibilities)
        )
      end

      it do
        is_expected.to(
          allow_value(nil).for(:provider_verification_in_first_five_years)
        )
      end

      it do
        is_expected.to(
          validate_inclusion_of(:provider_verification_teaching_qualification)
            .in_array(["yes", "not_yet", "no_but_planned", "no_not_planned", nil])
        )
      end

      it do
        is_expected.to(
          validate_inclusion_of(:provider_verification_contract_type)
            .in_array(["permanent", "fixed_term", "variable_hours", nil])
        )
      end
    end
  end

  describe "#incomplete?" do
    context "when form is valid" do
      let(:params) do
        {
          provider_verification_teaching_responsibilities: true,
          provider_verification_in_first_five_years: true,
          provider_verification_teaching_qualification: "yes",
          provider_verification_contract_type: "permanent",
          provider_verification_role_and_experience_section_completed: true
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
          provider_verification_teaching_responsibilities: true,
          provider_verification_in_first_five_years: true,
          provider_verification_teaching_qualification: "yes",
          provider_verification_contract_type: "permanent",
          provider_verification_role_and_experience_section_completed: true
        }
      end

      it "updates the claim eligibility and returns true" do
        expect(form.save).to be(true)

        claim.eligibility.reload

        expect(
          claim.eligibility.provider_verification_teaching_responsibilities
        ).to be(true)

        expect(
          claim.eligibility.provider_verification_in_first_five_years
        ).to be(true)

        expect(
          claim.eligibility.provider_verification_teaching_qualification
        ).to eq("yes")

        expect(
          claim.eligibility.provider_verification_contract_type
        ).to eq("permanent")

        expect(
          claim.eligibility.provider_verification_role_and_experience_section_completed
        ).to be(true)
      end
    end
  end
end
