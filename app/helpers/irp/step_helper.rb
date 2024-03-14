module Irp::StepHelper
  def back_link(step)
    back_path = StepFlow.previous_step_path(step)
    link_to(t("steps.back"), back_path, class: "govuk-back-link") if back_path
  end

  def form_method(step)
    return :post if step.form.new_record?

    :patch
  end
end
