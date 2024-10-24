class Admin::PayrollRunDownloadsController < Admin::BaseAdminController
  before_action :ensure_payroll_operator, :find_payroll_run

  before_action :ensure_download_has_been_triggered, only: :show

  def new
  end

  def create
    @payroll_run.update!(downloaded_at: Time.zone.now, downloaded_by: admin_user)

    redirect_to admin_payroll_run_download_path(@payroll_run)
  end

  def show
    respond_to do |format|
      format.html

      format.csv do
        out = Payroll::PaymentsCsv.new(@payroll_run)
        send_data out.data, type: out.content_type, filename: out.filename
      end
    end
  end

  private

  def find_payroll_run
    @payroll_run = PayrollRun.find(params[:payroll_run_id])
  end

  def ensure_download_has_been_triggered
    redirect_to new_admin_payroll_run_download_path(@payroll_run) unless @payroll_run.download_triggered?
  end
end
