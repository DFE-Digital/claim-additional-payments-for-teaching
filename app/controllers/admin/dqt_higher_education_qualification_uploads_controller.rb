module Admin
  class DqtHigherEducationQualificationUploadsController < BaseAdminController
    before_action :ensure_service_admin

    rate_limit(
      to: 1,
      within: 30.seconds,
      only: :create,
      with: -> do
        redirect_to(
          new_admin_dqt_higher_education_qualification_upload_path,
          alert: "Too many requests"
        )
      end
    )

    def new
      @upload_form = DqtHigherEducationQualificationUploadForm.new(upload_params, admin_user)
    end

    def create
      @upload_form = DqtHigherEducationQualificationUploadForm.new(upload_params, admin_user)

      if @upload_form.invalid?
        render :new
      else
        @upload_form.run_import!
        flash[:notice] = "DQT higher education qualifications file uploaded and queued to be imported"

        redirect_to admin_claims_path
      end
    end

    private

    def upload_params
      params.fetch(:dqt_higher_education_qualification_upload, {}).permit(:file)
    end
  end
end
