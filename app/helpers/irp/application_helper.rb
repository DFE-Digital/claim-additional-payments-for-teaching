# frozen_string_literal: true

module Irp::ApplicationHelper
  def link_to_irp(name = "international relocation payment (IRP)")
    govuk_link_to(
      name,
      "https://www.gov.uk/government/publications/international-relocation-payments/international-relocation-payments",
      { target: "_blank" },
    )
  end

  def mailto_teach_in_england
    govuk_link_to("teach.inengland@education.gov.uk", "mailto:teach.inengland@education.gov.uk")
  end

  def mailto_irp_express_interest
    govuk_link_to("irp.expressinterest@education.gov.uk", "mailto:IRP.ExpressInterest@education.gov.uk")
  end

  def banner_feedback_form
    govuk_link_to("feedback", "https://forms.office.com/e/p45Wm1Vmxg", target: "_blank")
  end

  # TODO: these are an admin feature
  # def application_statuses
  #   ApplicationProgress
  #     .statuses
  #     .keys
  #     .map { |status| [status.humanize, status] }
  # end
  #
  # def application_statuses_options(selected: nil, all_statuses: false)
  #   statuses = application_statuses
  #   statuses = application_statuses.unshift(["All statuses", ""]) if all_statuses
  #
  #   options_for_select(statuses, selected:)
  # end
  #
  # def dashboard_link(window_param, label)
  #   current_window = params[:window] || "all"
  #   if current_window == window_param
  #     content_tag(:strong, label)
  #   else
  #     link_to(label, dashboard_path(window: window_param))
  #   end
  # end
end
