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

        file_download = FileDownload.create!(
          downloaded_by: admin_user,
          body: out.data,
          filename: filename,
          content_type: out.content_type,
          source_data_model: @payroll_run.class.to_s,
          source_data_model_id: @payroll_run.id
        )

        send_data file_download.body, type: file_download.content_type, filename: file_download.filename
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

  def filename
    "payroll_data_#{@payroll_run.created_at.to_date.iso8601}_#{short_id}.csv"
  end

  # Just in case it's downloaded multiple times in the same day
  def short_id
    SecureRandom.urlsafe_base64(10).tr("-_", "").first(6).downcase
  end
end
