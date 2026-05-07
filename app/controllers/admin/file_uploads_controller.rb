module Admin
  class FileUploadsController < BaseAdminController
    before_action :ensure_service_operator

    def show
      @file_upload = FileUpload.find(params[:id])

      if @file_upload.completed_processing_at.nil? && @file_upload.upload_errors.blank?
        response.headers["Refresh"] = "5"
      end
    end
  end
end
