module Admin
  class FeatureFlagsController < BaseAdminController
    before_action :ensure_service_operator

    def update
      feature_flags_params.each do |flag, value|
        case value
        when "true"
          FeatureFlag.enable!(flag)
        when "false"
          FeatureFlag.disable!(flag)
        end
      end

      redirect_back fallback_location: admin_journey_configurations_path
    end

    private

    def feature_flags_params
      params
        .require(:feature_flags)
        .permit(:fe_provider_dashboard)
    end
  end
end
