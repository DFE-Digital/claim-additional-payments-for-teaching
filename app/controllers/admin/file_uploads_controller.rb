module Admin
  class FileUploadsController < BaseAdminController
    before_action :ensure_service_operator

    def show
      @file_upload = FileUpload.find(params[:id])
    end
  end
end
