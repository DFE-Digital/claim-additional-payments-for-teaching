require "rails_helper"

RSpec.describe "Admin payroll runs", type: :feature do
  context "when signed in as a service operator" do
    before { @signed_in_user = sign_in_as_service_operator }

    describe "admin_payroll_runs#new" do
      it "displays a preview of the payrollable claims" do
        create(:claim, :approved, eligibility: create(:student_loans_eligibility, award_amount: 100))

        visit new_admin_payroll_run_path

        expect(page).to have_http_status(:unauthorized)
        expect(page).to have_text("Not authorised")
      end
    end

    describe "admin_payroll_runs#show" do
      it "displays a payroll run showing a link to the payroll run download" do
        payroll_run = create(:payroll_run)

        visit admin_payroll_run_path(payroll_run)

        expect(page).to have_http_status(:ok)
        expect(page.body).to include(new_admin_payroll_run_download_url(payroll_run))
      end

      it "allows for multiple downloads" do
        payroll_run = create(:payroll_run, downloaded_at: Time.zone.now)

        visit admin_payroll_run_path(payroll_run)

        expect(page).to have_http_status(:ok)
        expect(page.body).to include(new_admin_payroll_run_download_url(payroll_run))
      end

      it "shows who downloaded the payroll run once the download has been triggered" do
        payroll_run = create(:payroll_run, downloaded_at: Time.zone.now)

        visit admin_payroll_run_path(payroll_run)

        expect(page).to have_http_status(:ok)
        expect(page).to have_text(I18n.l(payroll_run.downloaded_at))
        expect(page).to have_text(payroll_run.downloaded_by.full_name)
      end
    end
  end

  context "when signed in as a service admin" do
    before { @signed_in_user = sign_in_as_service_admin }

    describe "admin_payroll_runs#new" do
      it "displays a preview of the payrollable claims" do
        create(:claim, :approved, eligibility: create(:student_loans_eligibility, award_amount: 100))

        visit new_admin_payroll_run_path

        expect(page).to have_http_status(:ok)
        expect(page).to have_text("£100")
      end
    end

    describe "admin_payroll_runs#create" do
      it "creates a payroll run with payments and redirects to it" do
        claims = create_list(:claim, 2, :approved)

        visit new_admin_payroll_run_path

        perform_enqueued_jobs do
          expect { click_button "Confirm and submit" }.to change { PayrollRun.count }.by(1)
        end

        payroll_run = PayrollRun.order(:created_at).last
        expect(payroll_run.created_by.id).to eq(@signed_in_user.id)
        expect(payroll_run.claims).to match_array(claims)
        expect(payroll_run.payments.count).to eq(2)

        expect(page.current_path).to eql(admin_payroll_run_path(payroll_run))
      end
    end
  end
end
