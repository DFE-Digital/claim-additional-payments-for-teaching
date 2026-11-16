require "rails_helper"

RSpec.describe Policies::TargetedRetentionIncentivePayments::StriDqtRecord do
  let!(:journey_config) do
    create(
      :journey_configuration,
      :targeted_retention_incentive_payments
    )
  end

  subject do
    described_class.new(record)
  end

  let(:record) { Dqt::Teacher.new(trs_data) }

  describe "#qts_years_exceeded?" do
    context "when exceeded" do
      let(:trs_data) do
        {
          qts: {
            holdsFrom: "2000-01-01"
          }
        }
      end

      it "returns truthy" do
        expect(subject.qts_years_exceeded?).to be_truthy
      end
    end

    context "when within range" do
      let(:trs_data) do
        {
          qts: {
            holdsFrom: "#{Date.today.year}-01-01"
          }
        }
      end

      it "returns falsey" do
        expect(subject.qts_years_exceeded?).to be_falsey
      end
    end
  end

  describe "#qts_years_too_early?" do
    context "when too early" do
      let(:trs_data) do
        {
          qts: {
            holdsFrom: "#{Date.today.year}-#{Date.today.month}-01"
          }
        }
      end

      it "returns truthy" do
        expect(subject.qts_years_too_early?).to be_truthy
      end
    end

    context "when within range" do
      let(:trs_data) do
        {
          qts: {
            holdsFrom: "#{Date.today.year - 10}-#{Date.today.month}-01"
          }
        }
      end

      it "returns falsey" do
        expect(subject.qts_years_too_early?).to be_falsey
      end
    end
  end

  describe "#qualification_eligible?" do
    context "when eligible" do
      let(:trs_data) do
        {
          routesToProfessionalStatuses: [
            {
              status: "Holds",
              routeToProfessionalStatusType: {
                name: Dqt::Matchers::General::QUALIFICATION_MATCHING_TYPE.values.flatten.sample
              }
            }
          ]
        }
      end

      it "returns truthy" do
        expect(subject.qualification_eligible?).to be_truthy
      end
    end

    context "when ineligible" do
      let(:trs_data) do
        {
          routesToProfessionalStatuses: []
        }
      end

      it "returns falsey" do
        expect(subject.qualification_eligible?).to be_falsey
      end
    end
  end

  describe "#subject_eligible?" do
    context "when eligible by code" do
      let(:trs_data) do
        {
          routesToProfessionalStatuses: [
            {
              status: "Holds",
              trainingSubjects: [
                reference: Policies::TargetedRetentionIncentivePayments::DqtRecord::ELIGIBLE_CODES.sample,
                name: "some subject"
              ]
            }
          ]
        }
      end

      it "returns truthy" do
        expect(subject.subject_eligible?).to be_truthy
      end
    end

    context "when eligible by name" do
      let(:trs_data) do
        {
          routesToProfessionalStatuses: [
            {
              status: "Holds",
              trainingSubjects: [
                reference: "wrong code",
                name: Dqt::Matchers::TargetedRetentionIncentivePayments::ELIGIBLE_ITT_SUBJECTS.values.flatten.sample
              ]
            }
          ]
        }
      end

      it "returns truthy" do
        expect(subject.subject_eligible?).to be_truthy
      end
    end

    context "when ineligible" do
      let(:trs_data) do
        {
          routesToProfessionalStatuses: []
        }
      end

      it "returns falsey" do
        expect(subject.subject_eligible?).to be_falsey
      end
    end
  end

  describe "#degree_code_eligible?" do
    context "when degree code is eligible" do
      let(:trs_data) do
        {
          trn: "1234567"
        }
      end

      before do
        create(
          :dqt_higher_education_qualification,
          teacher_reference_number: "1234567",
          subject_code: Policies::TargetedRetentionIncentivePayments::DqtRecord::ELIGIBLE_CODES.sample
        )
      end

      it "returns truthy" do
        expect(subject.degree_code_eligible?).to be_truthy
      end
    end

    context "when degree code is not eligible" do
      let(:trs_data) do
        {
          trn: "1234567"
        }
      end

      it "returns falsey" do
        expect(subject.degree_code_eligible?).to be_falsey
      end
    end
  end
end
