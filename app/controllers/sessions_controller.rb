class SessionsController < ApplicationController
  def new
  end

  def create
    session[:authenticated] = true
    redirect_to admin_path
  end

  def destroy
    session.destroy
    redirect_to root_path, notice: "You've been signed out"
  end
end
