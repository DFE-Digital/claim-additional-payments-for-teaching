module Admin
  class MyClaimsController < BaseAdminController
    before_action :ensure_service_operator

    def show
      @my_claims = MyClaims.new(current_admin: admin)
    end

    private

    def admin
      if params[:id]
        DfeSignIn::User.find(params[:id])
      else
        current_admin
      end
    end
  end
end
