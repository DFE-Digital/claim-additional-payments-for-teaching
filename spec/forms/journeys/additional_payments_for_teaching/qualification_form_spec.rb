require "rails_helper"

RSpec.describe Journeys::AdditionalPaymentsForTeaching::QualificationForm, type: :model do
  before { create(:journey_configuration, :additional_payments) }

  let(:journey) { Journeys::AdditionalPaymentsForTeaching }

  let(:journey_session) do
    create(
      :additional_payments_session,
      answers: {
        eligible_itt_subject: "mathematics",
        teaching_subject_now: true
      }
    )
  end

  let(:form) do
    described_class.new(
      journey: journey,
      journey_session: journey_session,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    let(:params) { ActionController::Parameters.new }

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
      let(:params) do
        ActionController::Parameters.new(claim: {qualification: "invalid"})
      end

      it "returns false" do
        expect { expect(form.save).to be false }.not_to(
          change { journey_session.reload.answers.qualification }
        )
      end
    end

    context "when valid" do
      let(:params) do
        ActionController::Parameters.new(
          claim: {qualification: "postgraduate_itt"}
        )
      end

      it "updates the answers" do
        expect { expect(form.save).to be true }.to(
          change { journey_session.reload.answers.qualification }
          .from(nil).to("postgraduate_itt")
        )
      end

      it "resets dependent answers if the details didn't come from dqt" do
        expect { expect(form.save).to be true }.to(
          change { journey_session.reload.answers.eligible_itt_subject }
          .from("mathematics").to(nil)
          .and(
            change { journey_session.reload.answers.eligible_itt_subject }
            .from("mathematics").to(nil)
          ).and(
            change { journey_session.reload.answers.teaching_subject_now }
            .from(true).to(nil)
          )
        )
      end

      it "doesn't reset dependent answers if the details came from dqt" do
        journey_session.answers.assign_attributes(
          qualifications_details_check: true
        )
        journey_session.save!

        expect { expect(form.save).to be true }.to(
          not_change { journey_session.reload.answers.eligible_itt_subject }
          .and(
            not_change { journey_session.reload.answers.eligible_itt_subject }
          ).and(
            not_change { journey_session.reload.answers.teaching_subject_now }
          )
        )
      end

      it "doesn't reset the answers if the qualification hasn't changed" do
        journey_session.answers.assign_attributes(
          qualification: "postgraduate_itt"
        )
        journey_session.save!

        expect { expect(form.save).to be true }.not_to(
          change { journey_session.reload.answers.eligible_itt_subject }
        )
      end
    end
  end
end
