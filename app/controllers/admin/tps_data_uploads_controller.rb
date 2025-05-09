module Admin
  class TpsDataUploadsController < BaseAdminController
    before_action :ensure_service_operator

    rate_limit(
      to: 1,
      within: 30.seconds,
      only: :create,
      with: -> do
        redirect_to(
          new_admin_tps_data_upload_path,
          alert: "Too many requests"
        )
      end
    )

    def new
      @upload_form = TpsDataForm.new(upload_params, admin_user)
    end

    def create
      @upload_form = TpsDataForm.new(upload_params, admin_user)

      if @upload_form.invalid?
        render :new
      else
        @upload_form.run_import!
        flash[:notice] = "Teachers Pensions Service data file uploaded and queued to be imported"

        redirect_to admin_claims_path
      end
    end

    private

    def upload_params
      params.fetch(:tps_data_upload, {}).permit(:file)
    end
  end
end
