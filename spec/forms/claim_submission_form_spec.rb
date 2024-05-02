require "rails_helper"

RSpec.describe ClaimSubmissionForm do
  before do
    create(:journey_configuration, :student_loans)
    create(:journey_configuration, :additional_payments)
  end

  let(:current_claim) do
    CurrentClaim.new(claims: Claim.where(id: claims.map(&:id)))
  end

  let(:params) do
    ActionController::Parameters.new(
      {
        claim: {
          selected_claim_policy: selected_policy
        }
      }
    )
  end

  let(:form) do
    described_class.new(
      journey: Journeys::AdditionalPaymentsForTeaching,
      claim: current_claim,
      params: params
    )
  end

  describe "validations" do
    let(:selected_policy) { nil }

    before { form.valid? }

    context "when the claim has already been submitted" do
      let(:claims) { [create(:claim, :submitted)] }

      it "is not submitable" do
        expect(form.errors[:base]).to include(
          "This claim has already been submitted"
        )
      end
    end

    context "when the claim is missing an email address" do
      let(:claims) { [create(:claim, :submittable, email_address: nil)] }

      it "is not submitable" do
        expect(form.errors[:base]).to include("Enter an email address")
      end
    end

    context "when the claim has an unverified email address" do
      let(:claims) { [create(:claim, :submittable, email_verified: false)] }

      it "is not submitable" do
        expect(form.errors[:base]).to include(
          "You must verify your email address before you can submit your claim"
        )
      end
    end

    context "when the teacher has choosen to provide their mobile number" do
      context "when the claim's mobile number is not from tid" do
        context "when the claim has an unverified mobile number" do
          let(:claims) do
            [
              create(
                :claim,
                :submittable,
                provide_mobile_number: true,
                mobile_verified: false,
                using_mobile_number_from_tid: false
              )
            ]
          end

          it "is not submitable" do
            expect(form.errors[:base]).to include(
              "You must verify your mobile number before you can submit your claim"
            )
          end
        end
      end
    end

    context "when the claim is ineligible" do
      let(:claims) do
        [
          create(
            :claim,
            eligibility: create(:student_loans_eligibility, :ineligible)
          )
        ]
      end

      it "is not submitable" do
        expect(form.errors[:base]).to include(
          "You’re not eligible for this payment"
        )
      end
    end
  end

  describe "#save" do
    let(:tslr_claim) do
      create(
        :claim,
        :submittable,
        policy: Policies::StudentLoans
      )
    end

    let(:ecp_claim) do
      create(
        :claim,
        :submittable,
        policy: Policies::EarlyCareerPayments
      )
    end

    let(:lup_claim) do
      create(
        :claim,
        :submittable,
        policy: Policies::LevellingUpPremiumPayments
      )
    end

    let(:incomplete_claim) do
      create(
        :claim,
        :submittable,
        postcode: nil
      )
    end

    around do |example|
      travel_to(DateTime.new(2024, 3, 1, 9, 0, 0)) { example.run }
    end

    before do
      allow(ClaimMailer).to receive(:submitted).and_return(
        double(deliver_later: true)
      )

      allow(ClaimVerifierJob).to receive(:perform_later)

      form.save
    end

    context "when valid" do
      context "when something has gone wrong" do
        let(:selected_policy) { nil }
        let(:claims) { [incomplete_claim] }

        it "doesn't submit the claim and returns errors" do
          expect(incomplete_claim.submitted_at).to eq nil

          expect(ClaimMailer).not_to(
            have_received(:submitted).with(incomplete_claim)
          )

          expect(ClaimVerifierJob).not_to(
            have_received(:perform_later).with(incomplete_claim)
          )

          expect(form.errors[:base]).to include("Postcode Enter a real postcode")
        end
      end

      context "when there is a single claim" do
        let(:selected_policy) { nil }
        let(:claims) { [tslr_claim] }

        it "submits the claim" do
          tslr_claim.reload

          expect(tslr_claim.submitted_at).to eq(
            DateTime.new(2024, 3, 1, 9, 0, 0)
          )

          expect(tslr_claim.reference).to be_present

          # student_loans/eligibility#submit! is a noop

          expect(ClaimMailer).to have_received(:submitted).with(tslr_claim)

          expect(ClaimVerifierJob).to(
            have_received(:perform_later).with(tslr_claim)
          )
        end
      end

      context "when there is a selected policy" do
        let(:selected_policy) { "LevellingUpPremiumPayments" }
        let(:claims) { [ecp_claim, lup_claim] }

        it "submits the claim that matches that policy" do
          lup_claim.reload

          expect(lup_claim.submitted_at).to eq(
            DateTime.new(2024, 3, 1, 9, 0, 0)
          )

          expect(lup_claim.reference).to be_present

          expect(lup_claim.eligibility.award_amount).to eq 2_000

          expect(ClaimMailer).to have_received(:submitted).with(lup_claim)

          expect(ClaimVerifierJob).to(
            have_received(:perform_later).with(lup_claim)
          )
        end

        it "removes the other claims" do
          expect(Claim.where(id: ecp_claim.id)).to be_empty
        end
      end

      context "when there is no selected policy" do
        let(:selected_policy) { nil }
        let(:claims) { [ecp_claim, lup_claim] }

        it "submits the main claim" do
          ecp_claim.reload

          expect(ecp_claim.submitted_at).to(
            eq(DateTime.new(2024, 3, 1, 9, 0, 0))
          )

          expect(ecp_claim.reference).to be_present

          expect(ecp_claim.eligibility.award_amount).to eq 2_000

          expect(ClaimMailer).to have_received(:submitted).with(ecp_claim)

          expect(ClaimVerifierJob).to(
            have_received(:perform_later).with(ecp_claim)
          )
        end

        it "removes the other claims" do
          expect(Claim.where(id: lup_claim.id)).to be_empty
        end
      end
    end
  end
end
