require "rails_helper"

RSpec.describe Journeys::GetATeacherRelocationPayment::ApplicationRouteForm, type: :model do
  let(:journey_session) { create(:get_a_teacher_relocation_payment_session) }

  let(:params) do
    ActionController::Parameters.new(claim: {application_route: option})
  end

  let(:form) do
    described_class.new(
      journey_session: journey_session,
      journey: Journeys::GetATeacherRelocationPayment,
      params: params
    )
  end

  describe "validations" do
    subject { form }

    let(:option) { nil }

    it do
      is_expected.to(
        validate_inclusion_of(:application_route)
        .in_array(%w[teacher salaried_trainee other])
        .with_message("Select the option that applies to you")
      )
    end
  end

  describe "#save" do
    let(:option) { "teacher" }

    it "udpates the journey session" do
      expect { expect(form.save).to be(true) }.to(
        change { journey_session.reload.answers.application_route }.to("teacher")
      )
    end

    describe "reseting dependent answers" do
      before do
        journey_session.answers.assign_attributes(
          application_route: existing_option,
          state_funded_secondary_school: true,
          one_year: true,
          start_date: Date.new(2024, 1, 1),
          subject: "physics"
        )
        journey_session.save!
      end

      context "when the value has changed" do
        let(:existing_option) { "salaried_trainee" }

        it "resets dependent answers" do
          expect { expect(form.save).to be(true) }.to(
            change { journey_session.reload.answers.state_funded_secondary_school }
            .from(true)
            .to(nil)
            .and(
              change { journey_session.reload.answers.one_year }
              .from(true)
              .to(nil)
            )
            .and(
              change { journey_session.reload.answers.start_date }
              .from(Date.new(2024, 1, 1))
              .to(nil)
            )
            .and(
              change { journey_session.reload.answers.subject }
              .from("physics")
              .to(nil)
            )
          )
        end
      end

      context "when the value hasn't changed" do
        let(:existing_option) { option }

        it "doesn't reset dependent answers if the value hasn't changed" do
          expect { expect(form.save).to be(true) }.to(
            not_change { journey_session.reload.answers.state_funded_secondary_school }
            .and(not_change { journey_session.reload.answers.one_year })
            .and(not_change { journey_session.reload.answers.start_date })
            .and(not_change { journey_session.reload.answers.subject })
          )
        end
      end
    end
  end
end
