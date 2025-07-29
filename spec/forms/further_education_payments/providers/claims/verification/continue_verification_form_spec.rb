require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::ContinueVerificationForm, type: :model do
  let(:fe_provider) do
    create(:school, :fe_eligible, name: "Springfield College")
  end

  let(:logged_in_user) { create(:dfe_signin_user) }
  let(:another_user) { create(:dfe_signin_user, given_name: "Boris", family_name: "Admin") }
  let(:provider_assigned_to_id) { another_user.id }

  let(:claim) do
    create(
      :claim,
      :further_education,
      eligibility_attributes: {provider_assigned_to_id: provider_assigned_to_id}
    )
  end

  let(:params) { {} }

  subject(:form) do
    described_class.new(
      claim: claim,
      user: logged_in_user,
      params: params
    )
  end

  describe "validations" do
    context "when submission" do
      it do
        is_expected.not_to(
          allow_value(nil).for(:continue_verification)
        )
      end

      it do
        is_expected.to(
          allow_value(true).for(:continue_verification)
        )
      end

      it do
        is_expected.to(
          allow_value(false).for(:continue_verification)
        )
      end
    end
  end

  describe "#incomplete?" do
    context "when not assigned" do
      let(:provider_assigned_to_id) { nil }

      it "returns false" do
        expect(form.incomplete?).to be(false)
      end
    end

    context "when assigned" do
      context "when logged in user is not assigned user" do
        it "returns true" do
          expect(form.incomplete?).to be(true)
        end
      end

      context "when logged in user is the assigned user" do
        let(:provider_assigned_to_id) { logged_in_user.id }

        it "returns false" do
          expect(form.incomplete?).to be(false)
        end
      end
    end
  end

  describe "#save" do
    context "when Yes is selected" do
      let(:params) do
        {continue_verification: true}
      end

      it "assigns the claim to the logged in user" do
        expect(form.save).to be(true)

        claim.eligibility.reload

        expect(
          claim.eligibility.provider_assigned_to_id
        ).to eq(logged_in_user.id)
      end
    end

    context "when No is selected" do
      let(:params) do
        {continue_verification: false}
      end

      it "the assignment remains unchanged" do
        expect(form.save).to be(true)

        claim.eligibility.reload

        expect(
          claim.eligibility.provider_assigned_to_id
        ).to eq(another_user.id)
      end
    end
  end

  describe "read_only?" do
    context "when Yes is selected" do
      let(:params) do
        {continue_verification: true}
      end

      it "returns true" do
        expect(form.read_only?).to be(false)
      end
    end

    context "when No is selected" do
      let(:params) do
        {continue_verification: false}
      end

      it "returns false" do
        expect(form.read_only?).to be(true)
      end
    end
  end

  describe "#started_by" do
    context "when assigned" do
      it "returns the full name of user" do
        expect(form.started_by).to eq("Boris Admin")
      end
    end

    context "when unassigned" do
      let(:provider_assigned_to_id) { nil }

      it "returns nil" do
        expect(form.started_by).to be_nil
      end
    end
  end
end
