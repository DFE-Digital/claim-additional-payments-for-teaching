module Admin
  class SchoolWorkforceCensusDataUploadsController < BaseAdminController
    before_action :ensure_service_operator

    def new
    end

    def create
      @school_workforce_census_data_importer = SchoolWorkforceCensusDataImporter.new(params[:file])

      if @school_workforce_census_data_importer.errors.any?
        render :new
      else
        @school_workforce_census_data_importer.run
        redirect_to admin_claims_path, notice: "School workforce census data uploaded successfully"
      end
    rescue ActiveRecord::RecordInvalid
      redirect_to new_admin_school_workforce_census_data_upload_path, alert: "There was a problem, please try again"
    end
  end
end
