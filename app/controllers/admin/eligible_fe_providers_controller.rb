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

      if @upload_form.invalid?
        render :new
      else
        @upload_form.importer.run
        flash[:notice] = @upload_form.importer.results_message

        redirect_to new_admin_eligible_fe_providers_path
      end
    end

    def show
      @download_form = EligibleFeProvidersForm.new(download_params)

      send_data EligibleFeProvider.csv_for_academic_year(@download_form.academic_year),
        type: "text/csv",
        filename: "eligible_further_education_providers_#{@download_form.academic_year}.csv"
    end

    private

    def upload_params
      params.require(:eligible_fe_providers).permit(:academic_year, :file)
    end

    def download_params
      params.require(:eligible_fe_providers).permit(:academic_year)
    end
  end
end
