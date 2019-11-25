require "rails_helper"

RSpec.describe "Admin payroll run downloads" do
  describe "downloads#new" do
    it "shows a form to download a payroll_run file" do
      sign_in_to_admin_with_role(AdminSession::SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)

      payroll_run = create(:payroll_run)

      get new_admin_payroll_run_download_path(payroll_run)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("#{Date.today.strftime("%B")} payroll file")
    end
  end
end
