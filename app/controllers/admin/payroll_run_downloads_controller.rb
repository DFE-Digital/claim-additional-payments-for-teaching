class Admin::PayrollRunDownloadsController < Admin::BaseAdminController
  before_action :ensure_service_operator, :find_payroll_run

  before_action :ensure_download_has_been_triggered, only: :show
  before_action :ensure_download_is_available, only: :show
  before_action :ensure_download_not_already_triggered, only: [:new, :create]

  def new
  end

  def create
    @payroll_run.update!(downloaded_at: Time.zone.now, downloaded_by: admin_session.user_id)

    redirect_to admin_payroll_run_download_path(@payroll_run)
  end

  def show
    respond_to do |format|
      format.html
      format.csv do
        csv = Payroll::ClaimsCsv.new(@payroll_run)
        send_file csv.file, type: "text/csv", filename: csv.filename
      end
    end
  end

  private

  def find_payroll_run
    @payroll_run = PayrollRun.find(params[:payroll_run_id])
  end

  def ensure_download_not_already_triggered
    redirect_to admin_payroll_run_download_path(@payroll_run) if @payroll_run.download_triggered?
  end

  def ensure_download_has_been_triggered
    redirect_to new_admin_payroll_run_download_path(@payroll_run) unless @payroll_run.download_triggered?
  end

  def ensure_download_is_available
    return unless request.format.csv?
    redirect_to admin_payroll_run_download_path(@payroll_run, format: :html) unless @payroll_run.download_available?
  end
end
