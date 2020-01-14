class SessionsController < BasePublicController
  def refresh
    head :ok
  end

  def destroy
    clear_claim_session
    redirect_to(new_claim_path(params[:policy]))
  end
end
