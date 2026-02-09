module Admin
  class ClaimantFlagsCsvUploadsController < BaseAdminController
    before_action :ensure_service_operator

    def new
      @form = ClaimantFlagsCsvUploadForm.new(claimant_flags_csv_upload_params)
    end

    def create
      @form = ClaimantFlagsCsvUploadForm.new(claimant_flags_csv_upload_params)

      if @form.save
        redirect_to(
          admin_claims_path,
          notice: "Flagged claimants CSV uploaded successfully."
        )
      else
        render :new
      end
    end

    private

    def claimant_flags_csv_upload_params
      params
        .fetch(ClaimantFlagsCsvUploadForm.model_name.param_key, {})
        .permit(:file)
        .merge(admin: current_admin)
    end
  end
end
