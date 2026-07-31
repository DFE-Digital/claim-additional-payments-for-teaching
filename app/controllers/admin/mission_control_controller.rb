class Admin::MissionControlController < Admin::BaseAdminController
  before_action :ensure_service_operator

  private

  def admin_sign_in_path
    "/admin/auth/sign-in"
  end
end
