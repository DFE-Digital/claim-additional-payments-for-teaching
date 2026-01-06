module Admin
  class EventsController < BaseAdminController
    before_action :ensure_service_operator

    def index
      @claim = Claim.find(params[:claim_id])
      @events = @claim.events.order(created_at: :desc)
    end
  end
end
