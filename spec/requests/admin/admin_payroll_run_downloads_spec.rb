require "rails_helper"

RSpec.describe "Admin payroll run downloads" do
  let(:admin) { create(:dfe_signin_user) }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE, admin.dfe_sign_in_id)
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

    context "when requesting zip" do
      it "allows the payroll run file to be downloaded" do
        payroll_run = create(:payroll_run, downloaded_at: Time.zone.now, downloaded_by: admin)
        get admin_payroll_run_download_path(payroll_run, format: :csv)

        expect(response.headers["Content-Type"]).to eq("text/csv")
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
    context "when signed is as service operator or a payroll operator" do
      [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE].each do |role|
        it "responds with success", :aggregate_failures do
          payroll_run = create(:payroll_run)

          sign_in_to_admin_with_role(role)

          get new_admin_payroll_run_download_path(payroll_run)

          expect(response.code).to eq("200")

          get admin_payroll_run_download_path(payroll_run)

          expect(response).to redirect_to(new_admin_payroll_run_download_path)

          post admin_payroll_run_download_path(payroll_run)

          expect(response).to redirect_to(admin_payroll_run_download_path)
        end
      end
    end

    context "when signed in as a support agent" do
      let(:role) { DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE }

      it "responds with not authorised", :aggregate_failures do
        payroll_run = create(:payroll_run)

        sign_in_to_admin_with_role(role)

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
