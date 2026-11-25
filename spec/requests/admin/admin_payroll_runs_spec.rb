require "rails_helper"

RSpec.describe "Admin payroll runs" do
  let(:payroll_run) { create(:payroll_run) }

  def expect_read_access(status)
    get admin_payroll_runs_path
    expect(response).to have_http_status(status)

    get admin_payroll_run_path(payroll_run)
    expect(response).to have_http_status(status)
  end

  def expect_write_access_forbidden(status)
    get new_admin_payroll_run_path
    expect(response).to have_http_status(status)

    expect { post admin_payroll_runs_path }
      .not_to change(PayrollRun, :count)
    expect(response).to have_http_status(status)

    expect { delete admin_payroll_run_path(payroll_run) }
      .not_to change(PayrollRun, :count)
    expect(response).to have_http_status(status)
  end

  context "when the admin_permissions feature flag is disabled" do
    context "when signed in as a service operator" do
      before do
        operator = sign_in_as_service_operator
        create(
          :admin_permissions_grant,
          user: operator,
          permission: "payroll.write"
        )
      end

      it "allows viewing but not changing payroll runs, even with a grant" do
        expect_read_access(:ok)
        expect_write_access_forbidden(:unauthorized)
      end
    end

    context "when signed in as a service admin" do
      before { sign_in_as_service_admin }

      it "allows viewing and creating payroll runs without any grants" do
        expect_read_access(:ok)

        get new_admin_payroll_run_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "when the admin_permissions feature flag is enabled" do
    before { FeatureFlag.enable!(:admin_permissions) }

    let(:admin) { create(:dfe_signin_user, :service_admin) }

    before { sign_in_with_admin(admin) }

    context "when the user has no grants" do
      it "does not allow viewing or changing payroll runs" do
        expect_read_access(:forbidden)
        expect_write_access_forbidden(:forbidden)
      end
    end

    context "when the user has been granted admin.read" do
      before do
        create(:admin_permissions_grant, user: admin, permission: "admin.read")
      end

      it "allows viewing but not changing payroll runs" do
        expect_read_access(:ok)
        expect_write_access_forbidden(:forbidden)
      end
    end

    context "when the user has been granted payroll.write" do
      before do
        create(
          :admin_permissions_grant,
          user: admin,
          permission: "payroll.write"
        )
      end

      it "allows changing but not viewing payroll runs" do
        expect_read_access(:forbidden)

        get new_admin_payroll_run_path
        expect(response).to have_http_status(:ok)

        post admin_payroll_runs_path
        expect(response).to redirect_to(new_admin_payroll_run_path)

        delete admin_payroll_run_path(payroll_run)
        expect(response).to redirect_to(admin_payroll_runs_path)
      end
    end
  end
end
