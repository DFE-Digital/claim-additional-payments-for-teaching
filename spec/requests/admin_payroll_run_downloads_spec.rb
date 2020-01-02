require "rails_helper"

RSpec.describe "Admin payroll run downloads" do
  let(:admin_session_id) { "some_user_id" }

  before do
    sign_in_to_admin_with_role(DfeSignIn::User::PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE, admin_session_id)
  end

  describe "downloads#new" do
    it "shows a form to download a payroll_run file" do
      payroll_run = create(:payroll_run)

      get new_admin_payroll_run_download_path(payroll_run)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("#{Date.today.strftime("%B")} payroll file")
    end

    it "redirects to the show action if the download has already been triggered for the payroll run" do
      payroll_run = create(:payroll_run, downloaded_at: Time.zone.now, downloaded_by: admin_session_id)

      expect(get(new_admin_payroll_run_download_path(payroll_run))).to redirect_to admin_payroll_run_download_path(payroll_run)
    end
  end

  describe "downloads#show" do
    it "redirects to the new action when payroll run download has not been triggered" do
      payroll_run = create(:payroll_run)

      [:html, :csv].each do |format|
        expect(get(admin_payroll_run_download_path(payroll_run, format: format))).to redirect_to new_admin_payroll_run_download_path(payroll_run)
      end
    end

    context "when requesting html" do
      context "and it is within the timeout" do
        it "shows a link to download the payroll run file" do
          payroll_run = create(:payroll_run, downloaded_at: Time.zone.now, downloaded_by: admin_session_id)

          get admin_payroll_run_download_path(payroll_run)

          expect(response.body).to include admin_payroll_run_download_path(payroll_run, format: :csv)

          travel_to 31.seconds.from_now do
            get admin_payroll_run_download_path(payroll_run)

            expect(response.body).not_to include admin_payroll_run_download_path(payroll_run, format: :csv)
          end
        end
      end

      context "and the timeout has been reached" do
        it "shows who triggered the download and when" do
          payroll_run = create(:payroll_run, downloaded_at: 31.seconds.ago, downloaded_by: "admin_user_id")

          get admin_payroll_run_download_path(payroll_run)

          expect(response.body).to include payroll_run.downloaded_by
          expect(response.body).to include I18n.l(payroll_run.downloaded_at)
        end
      end
    end

    context "when requesting csv" do
      context "and it is within the timeout" do
        it "allows the payroll run file to be downloaded within the time limit" do
          payroll_run = create(:payroll_run, downloaded_at: Time.zone.now, downloaded_by: "admin_user_id")
          get admin_payroll_run_download_path(payroll_run, format: :csv)

          expect(response.headers["Content-Type"]).to eq("text/csv")
        end
      end

      context "and the timeout has been reached" do
        it "redirects a request for the file once the timeout has been reached" do
          payroll_run = create(:payroll_run, downloaded_at: 31.seconds.ago, downloaded_by: "admin_user_id")

          expect(get(admin_payroll_run_download_path(payroll_run, format: :csv))).to redirect_to admin_payroll_run_download_path(payroll_run, format: :html)
        end
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

          expect(payroll_run.reload.downloaded_by).to eql admin_session_id
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

  describe "When signed in as a service operator or a support agent, download routes" do
    [DfeSignIn::User::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, DfeSignIn::User::SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE].each do |role|
      it "respond with not authorised" do
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
