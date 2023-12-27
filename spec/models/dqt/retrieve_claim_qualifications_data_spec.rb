require "rails_helper"

RSpec.describe Dqt::RetrieveClaimQualificationsData do
  let(:dbl) { double(find_raw: response) }
  let(:response) { { "mock" => "mock" } }
  let(:claim) { build(:claim, :submittable, dqt_teacher_status:) }

  before do
    allow(Dqt::TeacherResource).to receive(:new).and_return(dbl)
  end

  describe "#save_qualifications_result" do
    subject(:service) { described_class.new(claim) }

    context "when the claim already has a saved DQT payload" do
      let(:dqt_teacher_status) { { "test" => "test" } }

      it "does not retrieve a new DQT payload" do
        expect(dbl).not_to receive(:find_raw)
        expect { service.save_qualifications_result }.not_to change { claim.dqt_teacher_status }
      end
    end

    context "when the claim already has a saved DQT payload that is empty" do
      let(:dqt_teacher_status) { {} }

      it "does not retrieve a new DQT payload" do
        expect(dbl).not_to receive(:find_raw)
        expect { service.save_qualifications_result }.not_to change { claim.dqt_teacher_status }
      end
    end

    context "when the claim does not have a saved DQT payload" do
      let(:dqt_teacher_status) { nil }

      it "retrieves and saves the DQT payload" do
        expect(dbl).to receive(:find_raw).with(claim.teacher_reference_number, birthdate: claim.date_of_birth.to_s, nino: claim.national_insurance_number)
        expect { service.save_qualifications_result }.to change { claim.dqt_teacher_status }.from(dqt_teacher_status).to(response)
      end
    end
  end
end
