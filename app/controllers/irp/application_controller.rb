# frozen_string_literal: true

module Irp
  class ApplicationController < ActionController::Base
    layout "irp"
    default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder

    helper_method :current_policy_routing_name
    before_action :check_whether_closed_for_submissions

    # reused from Claim
    def check_whether_closed_for_submissions
      irp_journey_configuration = JourneyConfiguration.for(Irp)
      unless irp_journey_configuration.open_for_submissions?
        @availability_message = irp_journey_configuration.availability_message
        render "static_pages/closed_for_submissions", status: :service_unavailable
      end
    end

    def current_policy_routing_name
      Irp.routing_name
    end

    def current_form
      @current_form ||= Form.find_by(id: session["form_id"])
    end
  end
end
