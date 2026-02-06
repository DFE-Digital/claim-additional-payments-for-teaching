module Admin
  class ClaimantFlagsCsvDownloadsController < BaseAdminController
    before_action :ensure_service_admin

    def show
      @claimant_flags = ClaimantFlag.all

      respond_to do |format|
        format.csv do
          send_data(
            generate_csv,
            filename: "claimant_flags-#{Time.zone.now.strftime("%Y%m%d%H%M%S")}.csv"
          )
        end
      end
    end

    private

    def generate_csv
      CSV.generate(headers: true) do |csv|
        csv << ["policy", "identification_attribute", "identification_value", "reason", "suggested_action"]

        @claimant_flags.find_each do |claimant_flag|
          csv << [
            claimant_flag.policy,
            claimant_flag.identification_attribute,
            claimant_flag.identification_value,
            claimant_flag.reason,
            claimant_flag.suggested_action
          ]
        end
      end
    end
  end
end
