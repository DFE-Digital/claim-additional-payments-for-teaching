require "rails_helper"

RSpec.describe Dqt::RetrieveClaimQualificationsData do
  let(:dbl) { double(find_raw: response) }
  let(:response) { {"mock" => "mock"} }
  let(:session) do
    build(
      :targeted_retention_incentive_payments_session,
      answers: attributes_for(
        :targeted_retention_incentive_payments_answers,
        :with_details_from_dfe_identity,
        dqt_teacher_status: dqt_teacher_status
      )
    )
  end

  before do
    allow(Dqt::TeacherResource).to receive(:new).and_return(dbl)
  end

  describe "#save_qualifications_result" do
    subject(:service) { described_class.new(session) }

    context "when the claim already has a saved DQT payload" do
      let(:dqt_teacher_status) { {"test" => "test"} }

      it "does not retrieve a new DQT payload" do
        expect(dbl).not_to receive(:find_raw)
        expect { service.save_qualifications_result }.not_to(
          change { session.answers.dqt_teacher_status }
        )
      end
    end

    context "when the claim already has a saved DQT payload that is empty" do
      let(:dqt_teacher_status) { {} }

      it "does not retrieve a new DQT payload" do
        expect(dbl).not_to receive(:find_raw)
        expect { service.save_qualifications_result }.not_to(
          change { session.answers.dqt_teacher_status }
        )
      end
    end

    context "when the claim does not have a saved DQT payload" do
      let(:dqt_teacher_status) { nil }

      it "retrieves and saves the DQT payload" do
        expect(dbl).to receive(:find_raw).with(
          session.answers.teacher_reference_number,
          {include: "alerts,induction,routesToProfessionalStatuses"}
        )
        expect { service.save_qualifications_result }.to(
          change { session.answers.dqt_teacher_status }
            .from(dqt_teacher_status).to(response)
        )
      end
    end
  end
end
