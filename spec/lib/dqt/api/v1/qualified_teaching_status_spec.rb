require "rails_helper"

module Dqt
  class Api
    class V1
      describe QualifiedTeachingStatus do
        subject(:qualified_teaching_status) { described_class.new(client: Client.new(host: "dqt.com")) }

        describe "#show" do
          subject(:show) { qualified_teaching_status.show(params: params_args) }

          let(:claim) { build(:claim, :submittable) }

          let(:params_args) do
            {
              teacher_reference_number: claim.teacher_reference_number,
              national_insurance_number: claim.national_insurance_number
            }
          end

          let!(:show_endpoint) do
            stub_qualified_teaching_status_show(claim: claim)
          end

          it "makes correct request" do
            show

            expect(show_endpoint).to have_been_requested
          end

          it "returns qualified teaching status" do
            expect(show).to eq(
              {
                teacher_reference_number: claim.teacher_reference_number,
                first_name: claim.first_name,
                surname: claim.surname,
                date_of_birth: claim.date_of_birth,
                degree_codes: [],
                national_insurance_number: claim.national_insurance_number,
                qts_date: DateTime.parse("2021-03-23T10:54:57.199Z"),
                itt_subject_codes: [
                  "string",
                  "string",
                  "string"
                ],
                active_alert: true
              }
            )
          end
        end
      end
    end
  end
end
