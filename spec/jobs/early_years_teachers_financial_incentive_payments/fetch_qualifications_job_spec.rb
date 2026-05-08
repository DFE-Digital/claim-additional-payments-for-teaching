require "rails_helper"

RSpec.describe EarlyYearsTeachersFinancialIncentivePayments::FetchQualificationsJob do
  let(:journey_session) do
    create(
      :eytfi_session
    )
  end

  let(:response_hash) do
    {
      trn: "3013822",
      firstName: "Newell",
      middleName: "",
      lastName: "Ondricka",
      dateOfBirth: "1960-01-01",
      nationalInsuranceNumber: "LC882331C",
      emailAddress: nil,
      qts: nil,
      eyts: {
        holdsFrom: "2026-01-01",
        routes: [
          {
            routeToProfessionalStatusType: {
              routeToProfessionalStatusTypeId: "11b66de5-4670-4c82-86aa-20e42df723b7",
              name: "Early Years Teacher Degree Apprenticeship",
              professionalStatusType: "EarlyYearsTeacherStatus"
            }
          }
        ]
      },
      qtlsStatus: "None"
    }
  end

  let(:mock_teacher) do
    Dqt::Teacher.new(
      response_hash
    )
  end

  let(:mock_teacher_resource) do
    instance_double(
      "Dqt::TeacherResource",
      find: -> { mock_teacher }.call
    )
  end

  let(:mock_client) do
    instance_double(
      "Dqt::Client",
      teacher: mock_teacher_resource
    )
  end

  before do
    allow(Dqt::Client).to receive(:new).and_return(mock_client)
  end

  describe "#perform" do
    it "persists api call" do
      subject.perform(journey_session)

      expect(journey_session.reload.answers.trs_data).to eql(response_hash.deep_stringify_keys)
    end

    it "touches trs_data_fetched_at" do
      expect {
        subject.perform(journey_session)
      }.to change { journey_session.reload.answers.trs_data_fetched_at }
    end

    it "calculates and persists has_eligible_qualification" do
      expect {
        subject.perform(journey_session)
      }.to change { journey_session.reload.answers.has_eligible_qualification }.from(nil).to(true)
    end

    context "when user for api call does not have eligible qualifications" do
      let(:response_hash) do
        {
          trn: "3013822",
          firstName: "Newell",
          middleName: "",
          lastName: "Ondricka",
          dateOfBirth: "1960-01-01",
          nationalInsuranceNumber: "LC882331C",
          emailAddress: nil,
          qts: nil,
          eyts: nil,
          qtlsStatus: "None"
        }
      end

      it "persists has_eligible_qualification to false" do
        expect {
          subject.perform(journey_session)
        }.to change { journey_session.reload.answers.has_eligible_qualification }.from(nil).to(false)
      end
    end

    context "when trs_data_fetched_at is set" do
      it "does not make an api call again" do
        subject.perform(journey_session)
        subject.perform(journey_session)

        expect(Dqt::Client).to have_received(:new).once
      end
    end
  end
end
