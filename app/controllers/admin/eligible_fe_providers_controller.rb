module Admin
  class EligibleFeProvidersController < BaseAdminController
    before_action :ensure_service_operator

    def new
      @upload_form = EligibleFeProvidersForm.new
      @download_form = EligibleFeProvidersForm.new
    end

    def create
      @download_form = EligibleFeProvidersForm.new
      @upload_form = EligibleFeProvidersForm.new(upload_params)

      if @upload_form.invalid? || importer.invalid?
        @upload_form.errors.merge!(importer.errors)

        render :new
      else
        importer.call
        flash[:notice] = importer.results_message

        redirect_to new_admin_eligible_fe_providers_path
      end
    end

    def show
      send_data EligibleFeProvider.csv_for_academic_year(academic_year),
        type: "text/csv",
        filename: "eligible_further_education_providers_#{academic_year}.csv"
    end

    private

    def upload_params
      params.require(:eligible_fe_providers).permit(:academic_year, :file)
    end

    def download_params
      params.require(:eligible_fe_providers).permit(:academic_year)
    end

    def academic_year
      @academic_year ||= AcademicYear.new(params[:eligible_fe_providers][:academic_year])
    end

    def importer
      @importer ||= Importers::EligibleFeProviders.new(
        file: upload_params[:file]&.tempfile,
        academic_year:
      )
    end
  end
end
