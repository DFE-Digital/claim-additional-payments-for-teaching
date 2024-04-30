require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::QualificationForm, type: :model do
  before { create(:journey_configuration, :additional_payments) }

  let(:additional_payments_journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:eligibility) do
    create(
      :early_career_payments_eligibility,
      eligible_itt_subject: "mathematics",
      teaching_subject_now: true
    )
  end

  let(:claim) do
    create(
      :claim,
      policy: Policies::EarlyCareerPayments,
      eligibility: eligibility
    )
  end

  let(:current_claim) { CurrentClaim.new(claims: [claim]) }

  let(:params) do
    ActionController::Parameters.new(
      claim: {
        qualification: qualification
      }
    )
  end

  let(:form) do
    described_class.new(
      journey: additional_payments_journey,
      claim: current_claim,
      params: params
    )
  end

  describe "validations" do
    let(:qualification) { nil }

    subject { form }

    it do
      is_expected.to(
        validate_inclusion_of(:qualification)
        .in_array(described_class::QUALIFICATION_OPTIONS)
        .with_message("Select the route you took into teaching")
      )
    end
  end

  describe "#save" do
    context "when invalid" do
      let(:qualification) { "invalid" }

      it "returns false" do
        expect { expect(form.save).to be false }.not_to(
          change { eligibility.reload.qualification }
        )
      end
    end

    context "when valid" do
      let(:qualification) { "postgraduate_itt" }

      context "when the claim has details from DQT" do
        it "updates the claim's eligibility" do
          expect { expect(form.save).to be true }.to(
            change { eligibility.reload.qualification }
            .from(nil).to("postgraduate_itt")
          )
        end

        it "resets dependent answers" do
          claim.update!(qualifications_details_check: true)

          form.save

          expect(eligibility.reload.eligible_itt_subject).to eq("mathematics")

          expect(eligibility.reload.teaching_subject_now).to eq(true)
        end
      end

      context "when the claim does not have details from DQT" do
        it "updates the claim's eligibility" do
          expect { expect(form.save).to be true }.to(
            change { eligibility.reload.qualification }
            .from(nil).to("postgraduate_itt")
          )
        end

        it "resets dependent answers" do
          expect { expect(form.save).to be true }.to(
            change { eligibility.reload.eligible_itt_subject }
            .from("mathematics").to(nil).and(
              change { eligibility.reload.teaching_subject_now }
                .from(true).to(nil)
            )
          )
        end
      end
    end
  end

  describe "#backlink_path" do
    let(:form) do
      described_class.new(
        journey: additional_payments_journey,
        claim: current_claim,
        params: ActionController::Parameters.new(
          {
            journey: "additional-payments",
            slug: "qualification"
          }
        )
      )
    end

    it "returns the previous page in the journey" do
      expect(form.backlink_path).to eq("/additional-payments/poor-performance")
    end
  end
end
