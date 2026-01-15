module Admin
  class MyClaimsController < BaseAdminController
    before_action :ensure_service_operator

    def show
      @my_claims = MyClaims.new(current_admin: admin)
    end

    private

    def admin
      DfeSignIn::User.find(params[:id])
    end
  end
end
