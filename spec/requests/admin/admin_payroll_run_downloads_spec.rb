require "rails_helper"

RSpec.describe "Admin payroll run downloads" do
  let(:admin) { create(:dfe_signin_user, :service_admin) }

  before do
    sign_in_with_admin(admin)
  end

  describe "downloads#new" do
    it "shows a form to download a payroll_run file" do
      payroll_run = create(:payroll_run)

      get new_admin_payroll_run_download_path(payroll_run)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("#{Date.today.strftime("%B")} payroll file")
    end

    context "when the file has been downloaded before" do
      it "shows who triggered the download and when" do
        payroll_run = create(:payroll_run, downloaded_at: 1.minute.ago, downloaded_by: admin)

        get new_admin_payroll_run_download_path(payroll_run)
        expect(response.body).to include payroll_run.downloaded_by.full_name
        expect(response.body).to include I18n.l(payroll_run.downloaded_at)
      end

      it "shows the user ID of the user if the user has not name assigned" do
        user = create(:dfe_signin_user, :without_data)
        payroll_run = create(:payroll_run, downloaded_at: 1.minute.ago, downloaded_by: user)

        get new_admin_payroll_run_download_path(payroll_run)
        expect(response.body).to include payroll_run.downloaded_by.dfe_sign_in_id
      end
    end
  end

  describe "downloads#show" do
    it "redirects to the new action" do
      payroll_run = create(:payroll_run)

      [:html, :zip].each do |format|
        expect(get(admin_payroll_run_download_path(payroll_run, format: format))).to redirect_to new_admin_payroll_run_download_path(payroll_run)
      end
    end

    context "when requesting html" do
      it "shows a link to download the payroll run file" do
        payroll_run = create(:payroll_run, downloaded_at: Time.zone.now, downloaded_by: admin)

        get admin_payroll_run_download_path(payroll_run)
        expect(response.body).to include admin_payroll_run_download_path(payroll_run, format: :csv)
      end
    end

    context "when requesting the csv file" do
      it "allows the payroll run file to be downloaded" do
        payroll_run = create(:payroll_run, downloaded_at: Time.zone.now, downloaded_by: admin)
        expect { get admin_payroll_run_download_path(payroll_run, format: :csv) }.to change { FileDownload.count }.from(0).to(1)

        expect(response.headers["Content-Type"]).to eq("text/csv")

        file_download = FileDownload.first
        expect(file_download.downloaded_by).to eq(admin)
        expect(file_download.body).to eq(response.body)
        expect(file_download.filename).to match(/payroll_data_\d{4}-\d\d-\d\d_[A-Za-z0-9]{6}.csv/)
        expect(file_download.content_type).to eq("text/csv")
        expect(file_download.source_data_model).to eq("PayrollRun")
        expect(file_download.source_data_model_id).to eq(payroll_run.id)
      end
    end
  end

  describe "downloads#create" do
    context "when the payroll run has not been triggered already" do
      let(:payroll_run) { create(:payroll_run) }

      it "sets the downloaded_at and downloaded_by attributes on the payroll_run" do
        downloaded_at = Time.zone.now

        travel_to downloaded_at do
          post admin_payroll_run_download_path(payroll_run)

          expect(payroll_run.reload.downloaded_by.id).to eql admin.id
          expect(payroll_run.downloaded_at.to_s).to eql downloaded_at.to_s
        end
      end

      it "redirects to the show action" do
        expect(post(admin_payroll_run_download_path(payroll_run))).to redirect_to admin_payroll_run_download_path(payroll_run)
      end
    end

    context "when the payroll run download has already been triggered" do
      let(:payroll_run) { create(:payroll_run) }

      it "does not set the downloaded_at and downloaded_by attributes on the payroll_run" do
        expect { post(admin_payroll_run_download_path(payroll_run)) }.not_to change { payroll_run.attributes }
      end

      it "redirects to the show action" do
        expect(post(admin_payroll_run_download_path(payroll_run))).to redirect_to admin_payroll_run_download_path(payroll_run)
      end
    end
  end

  describe "access restriction" do
    context "when signed is as service operator" do
      let(:admin) { create(:dfe_signin_user, :service_operator) }

      it "responds with failure", :aggregate_failures do
        payroll_run = create(:payroll_run)

        get new_admin_payroll_run_download_path(payroll_run)
        expect(response).to be_unauthorized

        get admin_payroll_run_download_path(payroll_run)
        expect(response).to be_unauthorized

        post admin_payroll_run_download_path(payroll_run)
        expect(response).to be_unauthorized
      end
    end

    context "when signed in as a support agent" do
      let(:admin) { create(:dfe_signin_user, :support_agent) }

      it "responds with not authorised", :aggregate_failures do
        payroll_run = create(:payroll_run)

        get new_admin_payroll_run_download_path(payroll_run)
        expect(response.code).to eq("401")
        expect(response.body).to include("Not authorised")

        get admin_payroll_run_download_path(payroll_run)
        expect(response.code).to eq("401")
        expect(response.body).to include("Not authorised")

        post admin_payroll_run_download_path(payroll_run)
        expect(response.code).to eq("401")
        expect(response.body).to include("Not authorised")
      end
    end
  end
end
