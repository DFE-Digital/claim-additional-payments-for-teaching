class UnsubscribeController < ApplicationController
  skip_forgery_protection

  def show
    @form = Unsubscribe::ConfirmationForm.new(form_params)

    if @form.reminder.nil?
      render "subscription_not_found"
    end
  end

  def create
    @form = Unsubscribe::ConfirmationForm.new(form_params)

    if @form.reminder.nil?
      head :bad_request
    else
      @form.reminder.mark_as_deleted!
    end
  end

  private

  def form_params
    params.permit([:id])
  end

  def current_journey_routing_name
    params[:journey]
  end
  helper_method :current_journey_routing_name

  def journey
    Journeys.for_routing_name(params[:journey])
  end
  helper_method :journey
end
