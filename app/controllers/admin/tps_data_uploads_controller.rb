module Admin
  class TpsDataUploadsController < BaseAdminController
    before_action :ensure_service_operator

    def new
    end

    def create
      file = params[:file]
      @tps_data_importer = TeachersPensionsServiceImporter.new(file)

      if @tps_data_importer.errors.any?
        render :new
      else
        file_upload = FileUpload.create(uploaded_by: admin_user, body: File.read(file))
        ImportTeachersPensionServiceDataJob.perform_later(file_upload.id)

        redirect_to admin_claims_path, notice: "Teachers Pensions Service data file uploaded and queued to be imported"
      end
    rescue ActiveRecord::RecordInvalid => e
      Rollbar.error(e)
      redirect_to new_admin_tps_data_upload_path, alert: "There was a problem, please try again"
    end
  end
end
