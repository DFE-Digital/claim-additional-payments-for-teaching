module Admin
  class SessionsController < BaseAdminController
    def refresh
      end_expired_admin_sessions

      head :ok
    end
  end
end
