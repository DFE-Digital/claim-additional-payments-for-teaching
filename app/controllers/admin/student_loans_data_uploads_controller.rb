module Admin
  class StudentLoansDataUploadsController < BaseAdminController
    before_action :ensure_service_operator

    rate_limit(
      to: 1,
      within: 30.seconds,
      only: :create,
      with: -> do
        redirect_to(
          new_admin_student_loans_data_upload_path,
          alert: "Too many requests"
        )
      end
    )

    def new
      @upload_form = StudentLoansCompanyDataForm.new(upload_params, admin_user)
    end

    def create
      @upload_form = StudentLoansCompanyDataForm.new(upload_params, admin_user)

      if @upload_form.invalid?
        render :new
      else
        @upload_form.run_import!
        flash[:notice] = "SLC file uploaded and queued to be imported"

        redirect_to admin_claims_path
      end
    end

    private

    def upload_params
      params.fetch(:student_loans_data_upload, {}).permit(:file)
    end
  end
end
