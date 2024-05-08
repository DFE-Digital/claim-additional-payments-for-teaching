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

    let(:ecp_eligibility) do
      build(
        :early_career_payments_eligibility,
        :eligible,
        award_amount: 1000.0
      )
    end

    let(:ecp_claim) do
      create(
        :claim,
        :submittable,
        policy: Policies::EarlyCareerPayments,
        eligibility: ecp_eligibility
      )
    end

    let(:lup_eligibility) do
      build(
        :levelling_up_premium_payments_eligibility,
        :eligible,
        award_amount: 2000.0
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

    before do
      allow(ClaimSubmissionService).to receive(:call)

      form.save
    end

    context "when valid" do
      context "when something has gone wrong" do
        let(:selected_policy) { nil }
        let(:claims) { [incomplete_claim] }

        it "doesn't submit the claim and returns errors" do
          expect(ClaimSubmissionService).not_to(have_received(:call))

          expect(form.errors[:base]).to include("Postcode Enter a real postcode")
        end
      end

      context "when there is a single claim" do
        let(:selected_policy) { nil }
        let(:claims) { [tslr_claim] }

        it "submits the claim" do
          expect(ClaimSubmissionService).to(have_received(:call).with(
            main_claim: tslr_claim,
            other_claims: []
          ))
        end
      end

      context "when there is a selected policy" do
        let(:selected_policy) { "LevellingUpPremiumPayments" }
        let(:claims) { [ecp_claim, lup_claim] }

        it "submits the claim that matches that policy" do
          expect(ClaimSubmissionService).to(have_received(:call).with(
            main_claim: lup_claim,
            other_claims: [ecp_claim]
          ))
        end
      end

      context "when there is no selected policy" do
        let(:selected_policy) { nil }
        let(:claims) { [ecp_claim, lup_claim] }

        it "submits the main claim" do
          expect(ClaimSubmissionService).to(have_received(:call).with(
            main_claim: ecp_claim,
            other_claims: [lup_claim]
          ))
        end
      end
    end
  end
end
