require "rails_helper"

module Dqt
  class Api
    class V1
      describe QualifiedTeachingStatuses do
        subject(:qualified_teaching_statuses) { described_class.new(client: Client.new(host: "dqt.com")) }

        describe "#show" do
          subject(:show) { qualified_teaching_statuses.show(params: show_params) }

          let(:claim) { build(:claim, :submittable) }

          let(:show_params) do
            {
              teacher_reference_number: claim.teacher_reference_number,
              national_insurance_number: claim.national_insurance_number
            }
          end

          let!(:show_endpoint) do
            stub_qualified_teaching_statuses_show(show_endpoint_params)
          end

          let(:show_endpoint_params) do
            {
              body: {
                data: [
                  {
                    trn: claim.teacher_reference_number,
                    name: "#{claim.first_name} #{claim.surname}",
                    doB: claim.date_of_birth,
                    niNumber: claim.national_insurance_number,
                    qtsAwardDate: DateTime.parse("2021-03-23T10:54:57.199Z"),
                    ittSubject1Code: "G100",
                    ittSubject2Code: nil,
                    ittSubject3Code: nil,
                    activeAlert: true,
                    qualificationName: nil,
                    ittStartDate: DateTime.parse("2021-03-23T10:54:57.199Z")
                  }
                ]
              },
              query: {
                trn: claim.teacher_reference_number,
                ni: claim.national_insurance_number
              }
            }
          end

          it "makes correct request" do
            show

            expect(show_endpoint).to have_been_requested
          end

          it "returns QualifiedTeachingStatuses" do
            expect(show).to all(be_an(QualifiedTeachingStatus))
          end

          context "with no matches" do
            let(:show_endpoint_params) do
              {
                body: {
                  data: nil,
                  message: "No records found"
                },
                query: {
                  trn: claim.teacher_reference_number,
                  ni: claim.national_insurance_number
                },
                status: 404
              }
            end

            it "returns nil" do
              expect(show).to eq nil
            end
          end
        end
      end
    end
  end
end
