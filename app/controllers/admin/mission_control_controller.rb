class Admin::MissionControlController < Admin::BaseAdminController
  before_action :service_operator_signed_in?

  private

  def admin_sign_in_path
    "/admin/auth/sign-in"
  end
end
