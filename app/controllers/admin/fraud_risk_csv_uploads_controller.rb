module Admin
  class FraudRiskCsvUploadsController < BaseAdminController
    before_action :ensure_service_operator

    def new
      @form = FraudRiskCsvUploadForm.new
    end

    def create
      @form = FraudRiskCsvUploadForm.new(fraud_risk_csv_upload_params)

      if @form.save
        redirect_to(
          new_admin_fraud_risk_csv_upload_path,
          notice: "Fraud prevention list uploaded successfully."
        )
      else
        render :new
      end
    end

    private

    def fraud_risk_csv_upload_params
      params.fetch(:admin_fraud_risk_csv_upload_form, {}).permit(:file)
    end
  end
end
