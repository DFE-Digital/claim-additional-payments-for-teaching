class SessionsController < ApplicationController
  def new
  end

  def create
    session[:authenticated] = true
    redirect_to admin_path
  end
end
