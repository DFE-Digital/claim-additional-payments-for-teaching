require "rails_helper"

RSpec.describe EarlyYearsTeachersFinancialIncentivePayments::FetchQualificationsJob do
  describe "#perform" do
    let(:journey_session) do
      create(
        :eytfi_session,
        answers: {
          teacher_auth_teacher_reference_number: "1234567"
        }
      )
    end

    around do |example|
      travel_to DateTime.new(2026, 6, 1, 0, 0, 0) do
        example.run
      end
    end

    context "when the teacher holds EYTS" do
      before do
        stub_request(
          :get,
          "https://dqt-api.education.gov.uk/v3/persons/1234567?include=routesToProfessionalStatuses"
        ).with(
          headers: {
            "Authorization" => "Bearer 1234567890"
          }
        ).to_return(
          status: 200,
          body: {
            "trn" => "1234567",
            "firstName" => "Seymour",
            "middleName" => "",
            "dateOfBirth" => "1945-06-01",
            "nationalInsuranceNumber" => "AB123456C",
            "emailAddress" => nil,
            "qts" => nil,
            "eyts" => {
              "holdsFrom" => "2015-10-22",
              "routes" => [
                {
                  "routeToProfessionalStatusType" => {
                    "routeToProfessionalStatusTypeId" => "11111",
                    "name" => "EYTS ITT Migrated",
                    "professionalStatusType" => "EarlyYearsTeacherStatus"
                  }
                }
              ]
            },
            "routesToProfessionalStatuses" => [
              {
                "routeToProfessionalStatusId" => "222222",
                "routeToProfessionalStatusType" => {
                  "routeToProfessionalStatusTypeId" => "33333",
                  "name" => "EYTS ITT Migrated",
                  "professionalStatusType" => "EarlyYearsTeacherStatus"
                },
                "status" => "Holds",
                "holdsFrom" => "2015-10-22",
                "trainingStartDate" => "2014-09-30",
                "trainingEndDate" => nil,
                "trainingSubjects" => [],
                "trainingAgeSpecialism" => {
                  "type" => "Range"
                },
                "trainingCountry" => {
                  "reference" => "GB",
                  "name" => "United Kingdom"
                },
                "trainingProvider" => {
                  "ukprn" => "10000000",
                  "name" => "SpringField University"
                },
                "degreeType" => nil,
                "inductionExemption" => {
                  "isExempt" => false,
                  "exemptionReasons" => []
                }
              }
            ],
            "qtlsStatus" => "None"
          }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)
      end

      it "sets the qualification as eligible" do
        expect(journey_session.answers.has_eligible_qualification).to be true
      end

      it "sets the trs_data_fetched_at timestamp" do
        expect(journey_session.answers.trs_data_fetched_at).to(
          eq(DateTime.new(2026, 6, 1, 0, 0, 0))
        )
      end

      it "stores the trs data in the answers" do
        expect(journey_session.answers.trs_data).to(
          eq({
            "trn" => "1234567",
            "firstName" => "Seymour",
            "middleName" => "",
            "dateOfBirth" => "1945-06-01",
            "nationalInsuranceNumber" => "AB123456C",
            "emailAddress" => nil,
            "qts" => nil,
            "eyts" => {
              "holdsFrom" => "2015-10-22",
              "routes" => [
                {
                  "routeToProfessionalStatusType" => {
                    "routeToProfessionalStatusTypeId" => "11111",
                    "name" => "EYTS ITT Migrated",
                    "professionalStatusType" => "EarlyYearsTeacherStatus"
                  }
                }
              ]
            },
            "routesToProfessionalStatuses" => [
              {
                "routeToProfessionalStatusId" => "222222",
                "routeToProfessionalStatusType" => {
                  "routeToProfessionalStatusTypeId" => "33333",
                  "name" => "EYTS ITT Migrated",
                  "professionalStatusType" => "EarlyYearsTeacherStatus"
                },
                "status" => "Holds",
                "holdsFrom" => "2015-10-22",
                "trainingStartDate" => "2014-09-30",
                "trainingEndDate" => nil,
                "trainingSubjects" => [],
                "trainingAgeSpecialism" => {
                  "type" => "Range"
                },
                "trainingCountry" => {
                  "reference" => "GB",
                  "name" => "United Kingdom"
                },
                "trainingProvider" => {
                  "ukprn" => "10000000",
                  "name" => "SpringField University"
                },
                "degreeType" => nil,
                "inductionExemption" => {
                  "isExempt" => false,
                  "exemptionReasons" => []
                }
              }
            ],
            "qtlsStatus" => "None"
          })
        )
      end
    end

    context "when the teacher holds QTS" do
      before do
        stub_request(
          :get,
          "https://dqt-api.education.gov.uk/v3/persons/1234567?include=routesToProfessionalStatuses"
        ).with(
          headers: {
            "Authorization" => "Bearer 1234567890"
          }
        ).to_return(
          status: 200,
          body: {
            "trn" => "1234567",
            "firstName" => "Seymour",
            "middleName" => "T",
            "lastName" => "Skinner",
            "dateOfBirth" => "1945-06-01",
            "nationalInsuranceNumber" => "AB123456C",
            "emailAddress" => nil,
            "qts" => {
              "holdsFrom" => "2018-07-06",
              "routes" => [
                {
                  "routeToProfessionalStatusType" => {
                    "routeToProfessionalStatusTypeId" => "11111",
                    "name" => "HEI",
                    "professionalStatusType" => "QualifiedTeacherStatus"
                  }
                }
              ]
            },
            "eyts" => nil,
            "routesToProfessionalStatuses" => [
              {
                "routeToProfessionalStatusId" => "bff172d9-af4a-4018-a311-dedca59f431a",
                "routeToProfessionalStatusType" => {
                  "routeToProfessionalStatusTypeId" => "10078157-e8c3-42f7-a050-d8b802e83f7b",
                  "name" => "HEI",
                  "professionalStatusType" => "QualifiedTeacherStatus"
                },
                "status" => "Holds",
                "holdsFrom" => "2018-07-06",
                "trainingStartDate" => "2015-09-20",
                "trainingEndDate" => "2018-06-01",
                "trainingSubjects" => [
                  {
                    "reference" => "X121",
                    "name" => "Primary Foundation"
                  }
                ],
                "trainingAgeSpecialism" => {
                  "type" => "Range"
                },
                "trainingCountry" => {
                  "reference" => "GB",
                  "name" => "United Kingdom"
                },
                "trainingProvider" => {
                  "ukprn" => "10000000",
                  "name" => "SpringField University"
                },
                "degreeType" => {
                  "degreeTypeId" => "dbb7c27b-8a27-4a94-908d-4b4404acebd5",
                  "name" => "BA (Hons)"
                },
                "inductionExemption" => {
                  "isExempt" => false,
                  "exemptionReasons" => []
                }
              }
            ],
            "qtlsStatus" => "None"
          }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)
      end

      it "sets the qualification as eligible" do
        expect(journey_session.answers.has_eligible_qualification).to be true
      end

      it "sets the trs_data_fetched_at timestamp" do
        expect(journey_session.answers.trs_data_fetched_at).to(
          eq(DateTime.new(2026, 6, 1, 0, 0, 0))
        )
      end

      it "stores the trs data in the answers" do
        expect(journey_session.answers.trs_data).to(
          match(a_hash_including("trn" => "1234567"))
        )
      end
    end

    context "when the teacher holds EYPS" do
      before do
        stub_request(
          :get,
          "https://dqt-api.education.gov.uk/v3/persons/1234567?include=routesToProfessionalStatuses"
        ).with(
          headers: {
            "Authorization" => "Bearer 1234567890"
          }
        ).to_return(
          status: 200,
          body: {
            "trn" => "1234567",
            "firstName" => "Seymour",
            "middleName" => "",
            "lastName" => "Skinner",
            "dateOfBirth" => "1945-06-01",
            "nationalInsuranceNumber" => nil,
            "emailAddress" => nil,
            "qts" => nil,
            "eyts" => nil,
            "routesToProfessionalStatuses" => [
              {
                "routeToProfessionalStatusId" => "111111",
                "routeToProfessionalStatusType" => {
                  "routeToProfessionalStatusTypeId" => "22222",
                  "name" => "EYPS",
                  "professionalStatusType" => "EarlyYearsProfessionalStatus"
                },
                "status" => "Holds",
                "holdsFrom" => nil,
                "trainingStartDate" => "2012-01-01",
                "trainingEndDate" => "2012-07-31",
                "trainingSubjects" => [],
                "trainingAgeSpecialism" => {
                  "type" => "Range"
                },
                "trainingCountry" => {
                  "reference" => "GB",
                  "name" => "United Kingdom"
                },
                "trainingProvider" => {
                  "ukprn" => "10000000",
                  "name" => "SpringField University"
                },
                "degreeType" => nil,
                "inductionExemption" => {
                  "isExempt" => false,
                  "exemptionReasons" => []
                }
              }
            ],
            "qtlsStatus" => "None"
          }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)
      end

      it "sets the qualification as eligible" do
        expect(journey_session.answers.has_eligible_qualification).to be true
      end

      it "sets the trs_data_fetched_at timestamp" do
        expect(journey_session.answers.trs_data_fetched_at).to(
          eq(DateTime.new(2026, 6, 1, 0, 0, 0))
        )
      end

      it "stores the trs data in the answers" do
        expect(journey_session.answers.trs_data).to(
          match(a_hash_including("trn" => "1234567"))
        )
      end
    end

    context "when the teacher does not have a valid qualification" do
      before do
        stub_request(
          :get,
          "https://dqt-api.education.gov.uk/v3/persons/1234567?include=routesToProfessionalStatuses"
        ).with(
          headers: {
            "Authorization" => "Bearer 1234567890"
          }
        ).to_return(
          status: 200,
          body: {
            "trn" => "1234567",
            "firstName" => "Seymour",
            "middleName" => "",
            "lastName" => "Skinner",
            "dateOfBirth" => "1945-06-01",
            "nationalInsuranceNumber" => nil,
            "emailAddress" => nil,
            "qts" => nil,
            "eyts" => nil,
            "qtlsStatus" => "None"
          }.to_json,
          headers: {
            "Content-Type" => "application/json"
          }
        )

        described_class.perform_now(journey_session)
      end

      it "sets the qualification as ineligible" do
        expect(journey_session.answers.has_eligible_qualification).to be false
      end

      it "sets the trs_data_fetched_at timestamp" do
        expect(journey_session.answers.trs_data_fetched_at).to(
          eq(DateTime.new(2026, 6, 1, 0, 0, 0))
        )
      end
    end
  end
end
