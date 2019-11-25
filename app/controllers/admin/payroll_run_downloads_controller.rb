class Admin::PayrollRunDownloadsController < Admin::BaseAdminController
  def new
    @payroll_run = PayrollRun.find(params[:payroll_run_id])
  end
end
