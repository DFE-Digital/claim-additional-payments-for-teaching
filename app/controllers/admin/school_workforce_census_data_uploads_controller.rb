module Admin
  class SchoolWorkforceCensusDataUploadsController < BaseAdminController
    before_action :ensure_service_operator

    def new
    end

    def create
      @school_workforce_census_data_importer = SchoolWorkforceCensusDataImporter.new(file: params[:file])

      if @school_workforce_census_data_importer.errors.any?
        render :new
      else
        file_upload = FileUpload.create(uploaded_by: admin_user, body: @school_workforce_census_data_importer.rows.to_s)
        ImportCensusJob.perform_later(file_upload)

        redirect_to admin_claims_path, notice: "School workforce census file uploaded and queued to be imported"
      end
    rescue ActiveRecord::RecordInvalid
      redirect_to new_admin_school_workforce_census_data_upload_path, alert: "There was a problem, please try again"
    end
  end
end
