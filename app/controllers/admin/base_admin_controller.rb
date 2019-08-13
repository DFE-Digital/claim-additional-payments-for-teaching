module Admin
  class BaseAdminController < ApplicationController
    before_action :ensure_authenticated_user

    private

    def ensure_authenticated_user
      redirect_to admin_sign_in_path unless signed_in?
    end
  end
end
