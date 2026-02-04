require "rails_helper"

RSpec.describe Dqt::TeacherResource do
  let(:client) { Dqt::Client.new }

  describe "#find" do
    let(:trn) { 1234567 }
    let(:birthdate) { "1981-01-01" }
    let(:nino) { "AB123123A" }

    subject(:result) do
      described_class.new(client)
        .find(
          trn,
          include: "alerts,induction,routesToProfessionalStatuses"
        )
    end

    context "when DQT returns a payload" do
      let(:status) { 200 }

      let(:body) do
        {
          qts: {
            holdsFrom: qts_date.to_s
          }
        }
      end

      let(:qts_date) { (Date.today - 1.year) }

      before { stub_qualified_teaching_statuses_show(trn:, params: {birthdate:, nino:}, body:, status:) }

      it { is_expected.to be_a(Dqt::Teacher) }

      it "returns the response body" do
        expect(result.qts_award_date).to eq(qts_date)
      end
    end

    context "when DQT does not return a payload" do
      let(:status) { 404 }
      let(:body) { nil }

      before { stub_dqt_empty_response(trn:) }

      it { is_expected.to be nil }
    end
  end
end
