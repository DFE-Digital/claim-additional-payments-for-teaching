module Admin
  class FraudRiskCsvDownloadsController < BaseAdminController
    before_action :ensure_service_operator

    def show
      respond_to do |format|
        format.csv do
          send_data(csv, filename: "fraud_risk.csv")
        end
      end
    end

    private

    def csv
      CSV.generate do |csv|
        csv << %w[field value]

        RiskIndicator.order(created_at: :asc).pluck(:field, :value).each do |row|
          csv << row
        end
      end
    end
  end
end
