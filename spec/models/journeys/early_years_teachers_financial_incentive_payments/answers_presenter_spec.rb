require "rails_helper"

RSpec.describe Journeys::EarlyYearsTeachersFinancialIncentivePayments::AnswersPresenter, type: :model do
  let(:nursery) { create(:eligible_eytfi_provider, name: "Springfield nursery") }

  let(:base_answers) do
    {
      nursery_id: nursery.id,
      teacher_auth_verified_name: "John Doe",
      teacher_auth_email: "john@example.com"
    }
  end

  let(:journey_session) do
    create(:eytfi_session, answers: base_answers.merge(extra_answers))
  end

  let(:extra_answers) { {} }

  subject(:presenter) { described_class.new(journey_session) }

  describe "#identity_answers" do
    subject { presenter.identity_answers }

    it "has name as the first row" do
      expect(subject.first).to eq(["Name", "John Doe", nil])
    end

    it "has email address as the second row" do
      expect(subject.second).to eq(["Email address", "john@example.com", nil])
    end
  end

  describe "#nursery_answers" do
    subject { presenter.nursery_answers }

    context "when trs_data is blank" do
      let(:extra_answers) { {trs_data: nil} }

      it "does not include a qualification row" do
        expect(subject.map(&:first)).not_to include("Qualification")
      end
    end

    context "when teacher has valid QTS" do
      let(:extra_answers) do
        {
          trs_data: {
            "qts" => {
              "holdsFrom" => "2020-01-01",
              "routes" => [{"routeToProfessionalStatusType" => {"professionalStatusType" => "QualifiedTeacherStatus"}}]
            }
          }
        }
      end

      it "shows Qualified Teacher Status (QTS) as the last row" do
        expect(subject.last).to eq(["Qualification", "Qualified Teacher Status (QTS)", nil])
      end
    end

    context "when teacher has valid EYTS" do
      let(:extra_answers) do
        {
          trs_data: {
            "eyts" => {
              "holdsFrom" => "2020-01-01",
              "routes" => [{"routeToProfessionalStatusType" => {"professionalStatusType" => "EarlyYearsTeacherStatus"}}]
            }
          }
        }
      end

      it "shows Early Years Teacher Status (EYTS) as the last row" do
        expect(subject.last).to eq(["Qualification", "Early Years Teacher Status (EYTS)", nil])
      end
    end

    context "when teacher has valid EYPS" do
      let(:extra_answers) do
        {
          trs_data: {
            "eyts" => {
              "holdsFrom" => "2020-01-01",
              "routes" => [{"routeToProfessionalStatusType" => {"professionalStatusType" => "EarlyYearsProfessionalStatus"}}]
            }
          }
        }
      end

      it "shows Early Years Professional Status (EYPS) as the last row" do
        expect(subject.last).to eq(["Qualification", "Early Years Professional Status (EYPS)", nil])
      end
    end
  end
end
