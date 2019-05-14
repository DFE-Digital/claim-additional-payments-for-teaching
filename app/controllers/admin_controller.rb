class AdminController < ApplicationController
  before_action :ensure_authenticated_user

  def index
  end

  private

  def ensure_authenticated_user
    redirect_to new_sessions_path unless signed_in?
  end
end
