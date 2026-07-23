module Admin
  class PayrollProjectionsController < BaseAdminController
    before_action :ensure_service_operator

    def show
      @projection = Payroll::Projection.new
    end
  end
end
