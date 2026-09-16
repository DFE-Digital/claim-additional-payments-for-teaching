require "rails_helper"

RSpec.describe FurtherEducationPayments::Providers::Claims::Verification::CheckAnswersForm, type: :model do
  let(:user) { create(:dfe_signin_user) }

  let(:claim) do
    create(
      :claim,
      :further_education,
      eligibility_trait: :provider_verifiable
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
    it do
      is_expected.to(
        validate_presence_of(:provider_verification_declaration)
        .with_message("Check the box once you have read the declaration")
      )
    end
  end

  describe "#save" do
    let(:params) do
      {
        provider_verification_declaration: true
      }
    end

    context "with an incomplete form" do
      before do
        claim.eligibility.update!(
          provider_verification_teaching_responsibilities: nil
        )
      end

      it "throws an error" do
        expect { form.save }.to raise_error(
          described_class::IncompleteWizardError
        )
      end
    end

    context "with a complete form" do
      let(:verified_at) { DateTime.new(2025, 1, 1, 0, 0, 0) }

      let(:complete_form) do
        travel_to(verified_at) do
          form.save
        end
      end

      it "sets the claim as verified" do
        complete_form

        expect(
          claim.eligibility.provider_verification_completed_at
        ).to eq(verified_at)
      end

      it "records who verified the claim" do
        complete_form

        expect(
          claim.eligibility.provider_verification_verified_by_id
        ).to eq(user.id)
      end

      it "creates an event" do
        expect { complete_form }.to change {
          Event.where(name: "claim_fe_provider_verification_completed").count
        }.by(1)
      end
    end

    context "when alternative IDV was completed" do
      it "calls the alternative IDV completed hook" do
        claim.eligibility.update!(
          provider_verification_claimant_employment_check_declaration: true
        )

        allow(Policies::FurtherEducationPayments).to(
          receive(:alternative_idv_completed!)
        )

        form.save

        expect(Policies::FurtherEducationPayments).to(
          have_received(:alternative_idv_completed!).with(claim)
        )
      end
    end

    context "when alternative IDV was not completed" do
      it "calls the alternative IDV completed hook" do
        claim.eligibility.update!(
          provider_verification_claimant_employment_check_declaration: false
        )

        allow(Policies::FurtherEducationPayments).to(
          receive(:alternative_idv_completed!)
        )

        form.save

        expect(Policies::FurtherEducationPayments).not_to(
          have_received(:alternative_idv_completed!).with(claim)
        )
      end
    end
  end

  describe "#in_first_five_years" do
    context "when current academic year ahead of claim academic year" do
      before do
        claim.eligibility.update!(
          provider_verification_teaching_start_year: Date.new(2021).year
        )

        claim.update!(
          academic_year: AcademicYear.new(2025)
        )

        allow(AcademicYear).to receive(:current).and_return(AcademicYear.new(2026))
      end

      it do
        expect(subject.in_first_five_years).to eql("September 2021 to August 2022")
      end
    end

    context "when claim academic year matches current academic year" do
      before do
        claim.eligibility.update!(
          provider_verification_teaching_start_year: Date.new(2021).year
        )

        claim.update!(
          academic_year: AcademicYear.new(2025)
        )

        allow(AcademicYear).to receive(:current).and_return(AcademicYear.new(2025))
      end

      it do
        expect(subject.in_first_five_years).to eql("September 2021 to August 2022")
      end
    end
  end
end
