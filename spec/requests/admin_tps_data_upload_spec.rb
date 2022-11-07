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
        post admin_tps_data_uploads_path, params: {file: file}

        expect(response.body).to include("The selected file must be a CSV")
      end
    end

    context "when no CSV file is uploaded" do
      it "displays an error" do
        post admin_tps_data_uploads_path

        expect(response.body).to include("Select a file")
      end
    end

    [DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
      it "returns a unauthorized response for #{role} users" do
        sign_in_to_admin_with_role(role)

        post admin_tps_data_uploads_path

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when a valid CSV is uploaded" do
      def upload_tps_data_csm_file(file)
        perform_enqueued_jobs do
          post admin_tps_data_uploads_path, params: {file: file}
        end
      end

      before { create(:policy_configuration, :additional_payments, current_academic_year: "2021/2022") }

      context "when the claim is not TSLR" do
        let(:csv) do
          <<~CSV
            Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
            1000106,ZX043155C,01/07/2022,30/09/2022,24373,2031.08,5016,370,4027
            1000107,ZX043155C,01/07/2019,30/09/2019,24373,2031.08,5016,111,2222
            1000107,ZX043155C,01/07/2020,30/09/2020,24373,2031.08,5016,111,2222
            1000107,ZX043155C,01/07/2022,30/09/2022,24373,2031.08,5016,111,2222
          CSV
        end

        let!(:claim_matched) do
          create(
            :claim,
            :submitted,
            policy: EarlyCareerPayments,
            teacher_reference_number: 1000106,
            submitted_at: Date.new(2022, 7, 15),
            academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021))
          )
        end

        let!(:claim_no_match) do
          create(
            :claim,
            :submitted,
            policy: EarlyCareerPayments,
            teacher_reference_number: 1000107,
            submitted_at: Date.new(2022, 7, 15),
            academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021))
          )
        end

        let!(:claim_no_data) do
          create(
            :claim,
            :submitted,
            policy: EarlyCareerPayments,
            teacher_reference_number: 1000108,
            submitted_at: Date.new(2022, 7, 15),
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
            expect(claim_matched.notes.last[:body]).to eq "[Employment] - Eligible:\n<pre>Current school: LA Code: 370 / Establishment Number: 4027\n</pre>\n"
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
              Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
              #{claim_no_data.teacher_reference_number},ZX043155C,01/07/2022,30/09/2022,24373,2031.08,5016,#{claim_no_data.school.local_authority.code},#{claim_no_data.school.establishment_number}
            CSV

            file = Rack::Test::UploadedFile.new(StringIO.new(csv), "text/csv", original_filename: "tps_data.csv")

            expect { upload_tps_data_csm_file(file) }
              .to(
                change { claim_no_data.tasks.last.claim_verifier_match }.from(nil).to("all")
                .and(not_change { claim_no_data.tasks.size })
                .and(change { claim_no_data.notes.size }.from(1).to(2))
                .and(not_change { claim_no_match.tasks.last.updated_at })
                .and(not_change { claim_no_match.notes.size })
                .and(not_change { claim_matched.tasks.last.updated_at })
                .and(not_change { claim_matched.notes.size })
              )
          end
        end
      end

      context "when the claim is TSLR" do
        before { create(:policy_configuration, :student_loans, current_academic_year: "2021/2022") }

        let(:csv) do
          <<~CSV
            Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
            1000106,ZX043155C,01/07/2022,30/09/2022,24373,2031.08,5016,370,4027
            1000107,ZX043155C,01/07/2022,30/09/2022,24373,2031.08,5016,111,2222
            1000106,ZX043155C,01/07/2021,30/03/2022,24373,2031.08,5016,370,4027
          CSV
        end

        let!(:claim_matched) do
          create(
            :claim,
            :submitted,
            policy: StudentLoans,
            teacher_reference_number: 1000106,
            submitted_at: Date.new(2022, 7, 15),
            academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021))
          )
        end

        let!(:claim_no_match) do
          create(
            :claim,
            :submitted,
            policy: StudentLoans,
            teacher_reference_number: 1000107,
            submitted_at: Date.new(2022, 7, 15),
            academic_year: AcademicYear::Type.new.serialize(AcademicYear.new(2021))
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
            expect(claim_matched.notes.last[:body]).to eq "[Employment] - Eligible:\n<pre>Current school: LA Code: 370 / Establishment Number: 4027\nClaim school: LA Code: 370 / Establishment Number: 4027\n</pre>\n"
            expect(claim_no_match.notes.last[:body]).to eq "[Employment] - Ineligible:\n<pre>Current school: LA Code: 111 / Establishment Number: 2222\nClaim school: LA Code: 111 / Establishment Number: 2222\n</pre>\n"
            expect(claim_no_data.notes.last[:body]).to eq "[Employment] - No data"

            expect(response).to redirect_to(admin_claims_path)
          end
        end

        context "when a current school is ineligible and the claim school is eligible" do
          let(:csv) do
            <<~CSV
              Teacher reference number,NINO,Start Date,End Date,Annual salary,Monthly pay,N/A,LA URN,School URN
              1000106,ZX043155C,01/07/2022,30/09/2022,24373,2031.08,5016,371,4027
              1000106,ZX043155C,01/07/2021,30/03/2022,24373,2031.08,5016,370,4027
            CSV
          end

          it "runs the tasks, adds notes and redirects to the right page" do
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
              expect(claim_matched.notes.last[:body]).to eq "[Employment] - Ineligible:\n<pre>Current school: LA Code: 371 / Establishment Number: 4027\nClaim school: LA Code: 371 / Establishment Number: 4027\nClaim school: LA Code: 370 / Establishment Number: 4027\n</pre>\n"

              expect(response).to redirect_to(admin_claims_path)
            end
          end
        end
      end
    end
  end
end
