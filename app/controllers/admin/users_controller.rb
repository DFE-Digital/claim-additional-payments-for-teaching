module Admin
  class UsersController < BaseAdminController
    skip_before_action :ensure_authenticated_user

    def index
      @users = DfeSignIn::User.admin
    end

    def show
      @user = DfeSignIn::User.admin.find_by(id: params[:id])
      @form = form_class.new(user: @user, roles: @user.roles)
    end

    def update
      @user = DfeSignIn::User.admin.find_by(id: params[:id])
      @form = form_class.new(form_params.merge(user: @user))

      if @form.save
        redirect_to admin_users_path
      else
        render :show
      end
    end

    private

    def form_class
      Admin::Users::RolesForm
    end

    def form_params
      params.fetch(:form, {}).permit(roles: [])
    end
  end
end
