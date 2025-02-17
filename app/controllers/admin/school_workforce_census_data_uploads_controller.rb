module Admin
  class SchoolWorkforceCensusDataUploadsController < BaseAdminController
    before_action :ensure_service_operator

    rate_limit(
      to: 1,
      within: 30.seconds,
      only: :create,
      with: -> do
        redirect_to(
          new_admin_school_workforce_census_data_upload_path,
          alert: "Too many requests"
        )
      end
    )

    def new
    end

    def create
      file = params[:file]
      @school_workforce_census_data_importer = SchoolWorkforceCensusDataImporter.new(file)

      if @school_workforce_census_data_importer.errors.any?
        render :new
      else
        file_upload = FileUpload.create(uploaded_by: admin_user, body: File.read(file))
        ImportCensusJob.perform_later(file_upload.id)

        redirect_to admin_claims_path, notice: "School workforce census file uploaded and queued to be imported"
      end
    rescue => e
      Rollbar.error(e)
      redirect_to new_admin_school_workforce_census_data_upload_path, alert: "There was a problem, please try again"
    end
  end
end
