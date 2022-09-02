module Admin
  class TpsDataUploadsController < BaseAdminController
    before_action :ensure_service_operator

    def new
    end

    def create
      @tps_data_importer = TeachersPensionsServiceImporter.new(params[:file])

      if @tps_data_importer.errors.any?
        render :new
      else
        @tps_data_importer.run
        if @tps_data_importer.errors.any?
          render :new and return
        end
        perform_employment_checks
        redirect_to admin_claims_path, notice: "Teachers Pensions Service data uploaded successfully"
      end
    rescue ActiveRecord::RecordInvalid => e
      Rollbar.error(e)
      redirect_to new_admin_tps_data_upload_path, alert: "There was a problem, please try again"
    end

    private

    def perform_employment_checks
      delete_no_data_employment_tasks
      claims = Claim.awaiting_task("employment")

      claims.each do |claim|
        AutomatedChecks::ClaimVerifiers::Employment.new(
          claim: claim
        ).perform
      end
    end

    def delete_no_data_employment_tasks
      Task.where(name: "employment", claim_verifier_match: nil).delete_all
    end
  end
end
