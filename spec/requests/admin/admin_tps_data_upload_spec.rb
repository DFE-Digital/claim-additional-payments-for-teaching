require "rails_helper"

RSpec.describe "TPS data upload" do
  before do
    @signed_in_user = sign_in_as_service_operator
  end

  describe "#new" do
    it "shows the upload form" do
      get new_admin_tps_data_upload_path
      expect(response.body).to include("Choose and upload TPS data")
    end
  end

  describe "#create" do
    let(:file) { Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "tps_data.csv") }
    let(:csv) do
      <<~CSV
        Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay, ,LA URN,School URN
        1234567,ZX043155C,01/09/2019,30/09/2019,24373,2031.08,5016,383,4026
      CSV
    end

    context "when an invalid CSV is uploaded" do
      let(:csv) { "Malformed CSV File\"," }

      it "displays an error" do
        post admin_tps_data_uploads_path, params: {tps_data_upload: {file: file}}

        expect(response.body).to include("The selected file must be a CSV")
      end
    end

    context "when no CSV file is uploaded" do
      it "displays an error" do
        post admin_tps_data_uploads_path

        expect(response.body).to include("Choose a CSV file of Teacher Pensions Service data to upload")
      end
    end

    it "returns a unauthorized response for support agents" do
      sign_in_to_admin_with_role(DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)

      post admin_tps_data_uploads_path

      expect(response).to have_http_status(:unauthorized)
    end

    context "when a valid CSV is uploaded" do
      def upload_tps_data_csm_file(file)
        perform_enqueued_jobs do
          post admin_tps_data_uploads_path, params: {tps_data_upload: {file: file}}
        end
      end

      before { create(:journey_configuration, :targeted_retention_incentive_payments, current_academic_year: "2021/2022") }

      context "when the claim is not TSLR" do
        let(:school) { create(:school, :targeted_retention_incentive_payments_eligible) }
        let(:current_school) { school }
        let(:csv) do
          <<~CSV
            Teacher reference number,NINO,Start Date,End Date,LA URN,School URN,Employer ID
            1000106,ZX043155C,01/07/2022,30/09/2022,#{school.local_authority.code},#{school.establishment_number},1122
            1000107,ZX043155C,01/07/2019,30/09/2019,111,2222,1122
            1000107,ZX043155C,01/07/2020,30/09/2020,111,2222,1122
            1000107,ZX043155C,01/07/2022,30/09/2022,111,2222,1122
          CSV
        end

        let!(:claim_matched) do
          create(
            :claim,
            :submitted,
            policy: Policies::TargetedRetentionIncentivePayments,
            submitted_at: Date.new(2022, 7, 15),
            academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
            eligibility_attributes: {
              teacher_reference_number: 1000106,
              current_school: current_school
            }
          )
        end

        let!(:claim_no_match) do
          create(
            :claim,
            :submitted,
            policy: Policies::TargetedRetentionIncentivePayments,
            submitted_at: Date.new(2022, 7, 15),
            academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
            eligibility_attributes: {teacher_reference_number: 1000107}
          )
        end

        let!(:claim_no_data) do
          create(
            :claim,
            :submitted,
            policy: Policies::TargetedRetentionIncentivePayments,
            submitted_at: Date.new(2022, 7, 15),
            academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
            eligibility_attributes: {teacher_reference_number: 1000108}
          )
        end

        it "runs the tasks, adds notes and redirects to the right page" do
          aggregate_failures "testing tasks and notes" do
            expect { upload_tps_data_csm_file(file) }.to(
              change do
                [
                  claim_matched.reload.tasks.size,
                  claim_no_match.reload.tasks.size,
                  claim_no_data.reload.tasks.size,
                  claim_matched.reload.notes.size,
                  claim_no_match.reload.notes.size,
                  claim_no_data.reload.notes.size
                ]
              end
            )

            expect(claim_matched.tasks.last.claim_verifier_match).to eq "all"
            expect(claim_no_match.tasks.last.claim_verifier_match).to eq "none"
            expect(claim_no_data.tasks.last.claim_verifier_match).to be_nil
            expect(claim_matched.notes.last[:body]).to eq "[Employment] - Eligible:\n<pre>Current school: LA Code: #{school.local_authority.code} / Establishment Number: #{school.establishment_number}\n</pre>\n"
            expect(claim_no_match.notes.last[:body]).to eq "[Employment] - Ineligible:\n<pre>Current school: LA Code: 111 / Establishment Number: 2222\n</pre>\n"
            expect(claim_no_data.notes.last[:body]).to eq "[Employment] - No data"

            expect(response).to redirect_to(admin_claims_path)
          end
        end

        context "when uploading TPS data and claims marked as NO MATCH exist" do
          before do
            perform_enqueued_jobs do
              upload_tps_data_csm_file(file)
            end
          end

          it "runs the employment task again for NO MATCH claims" do
            csv = <<~CSV
              Teacher reference number,NINO,Start Date,End Date,LA URN,School URN,Employer ID
              #{claim_no_data.eligibility.teacher_reference_number},ZX043155C,01/07/2022,30/09/2022,#{claim_no_data.school.local_authority.code},#{claim_no_data.school.establishment_number},1122
            CSV

            file = Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "tps_data.csv")

            expect { upload_tps_data_csm_file(file) }
              .to(
                change { claim_no_data.tasks.last.claim_verifier_match }.from(nil).to("all")
                .and(not_change { claim_no_data.tasks.size })
                .and(change { claim_no_data.notes.size }.from(1).to(2))
                .and(change { claim_no_match.tasks.last.updated_at })
                .and(not_change { claim_no_match.tasks.last.passed })
                .and(change { claim_no_match.notes.size }.from(1).to(2))
                .and(not_change { claim_matched.tasks.last.updated_at })
                .and(not_change { claim_matched.notes.size })
              )
          end
        end
      end

      context "when the claim is TSLR" do
        before { create(:journey_configuration, :student_loans, current_academic_year: "2021/2022") }

        let(:school) { create(:school, :student_loans_eligible) }
        let(:claim_school) { school }
        let(:current_school) { claim_school }

        let(:csv) do
          <<~CSV
            Teacher reference number,NINO,Start Date,End Date,LA URN,School URN,Employer ID
            1000106,ZX043155C,01/07/2022,30/09/2022,#{school.local_authority.code},#{school.establishment_number},1122
            1000107,ZX043155C,01/07/2022,30/09/2022,111,2222,1122
            1000106,ZX043155C,01/07/2021,30/03/2022,#{school.local_authority.code},#{school.establishment_number},1122
          CSV
        end

        let!(:claim_matched) do
          create(
            :claim,
            :submitted,
            policy: Policies::StudentLoans,
            submitted_at: Date.new(2022, 7, 15),
            academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
            eligibility_attributes: {
              teacher_reference_number: 1000106,
              current_school: current_school,
              claim_school: claim_school
            }
          )
        end

        let!(:claim_no_match) do
          create(
            :claim,
            :submitted,
            policy: Policies::StudentLoans,
            submitted_at: Date.new(2022, 7, 15),
            academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021)),
            eligibility_attributes: {teacher_reference_number: 1000107}
          )
        end

        let!(:claim_no_data) do
          create(
            :claim,
            :submitted,
            academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021))
          )
        end

        it "runs the tasks, adds notes and redirects to the right page" do
          aggregate_failures "testing tasks and notes" do
            expect { upload_tps_data_csm_file(file) }.to(
              change do
                [
                  claim_matched.reload.tasks.size,
                  claim_no_match.reload.tasks.size,
                  claim_no_data.reload.tasks.size,
                  claim_matched.reload.notes.size,
                  claim_no_match.reload.notes.size,
                  claim_no_data.reload.notes.size
                ]
              end
            )

            expect(claim_matched.tasks.last.claim_verifier_match).to eq "all"
            expect(claim_no_match.tasks.last.claim_verifier_match).to eq "none"
            expect(claim_no_data.tasks.last.claim_verifier_match).to be_nil
            expect(claim_matched.notes.last[:body]).to eq "[Employment] - Eligible:\n<pre>Current school: LA Code: #{school.local_authority.code} / Establishment Number: #{school.establishment_number}\nClaim school: LA Code: #{school.local_authority.code} / Establishment Number: #{school.establishment_number}\n</pre>\n"
            expect(claim_no_match.notes.last[:body]).to eq "[Employment] - Ineligible:\n<pre>Current school: LA Code: 111 / Establishment Number: 2222\nClaim school: LA Code: 111 / Establishment Number: 2222\n</pre>\n"
            expect(claim_no_data.notes.last[:body]).to eq "[Employment] - No data"

            expect(response).to redirect_to(admin_claims_path)
          end
        end

        context "when a current school is ineligible and the claim school is eligible" do
          let(:csv) do
            <<~CSV
              Teacher reference number,NINO,Start Date,End Date,LA URN,School URN,Employer ID
              1000106,ZX043155C,01/07/2022,30/09/2022,371,#{school.establishment_number},1122
              1000106,ZX043155C,01/07/2021,30/03/2022,#{school.local_authority.code},#{school.establishment_number},1122
            CSV
          end

          it "runs the tasks, adds notes and redirects to the right page", flaky: true do
            aggregate_failures "testing tasks and notes" do
              expect { upload_tps_data_csm_file(file) }.to(
                change do
                  [
                    claim_matched.reload.tasks.size,
                    claim_matched.reload.notes.size
                  ]
                end
              )
              expect(claim_matched.tasks.last.claim_verifier_match).to eq "none"
              expect(claim_matched.notes.last[:body]).to eq "[Employment] - Ineligible:\n<pre>Current school: LA Code: 371 / Establishment Number: #{school.establishment_number}\nClaim school: LA Code: 371 / Establishment Number: #{school.establishment_number}\nClaim school: LA Code: #{school.local_authority.code} / Establishment Number: #{school.establishment_number}\n</pre>\n"

              expect(response).to redirect_to(admin_claims_path)
            end
          end
        end
      end
    end
  end
end
