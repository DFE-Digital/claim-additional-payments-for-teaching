#
# Checks that the form has all the required data
#

class Form::CompletenessCheck
  def initialize(form)
    @form = form
  end
  attr_reader :form

  def passed?
    !failed?
  end

  def failed?
    return true if failure_reason

    false
  end

  def failure_reason
    return if missing_fields.blank?

    "missing fields: #{missing_fields.join(', ')}"
  end

private

  def required_steps
    return ::StepFlow.teacher_steps if form.teacher_route?

    ::StepFlow.trainee_steps
  end

  def required_fields
    required_steps.flat_map { _1::REQUIRED_FIELDS }
  end

  def missing_fields
    required_fields.select { form.public_send(_1).to_s.blank? }
  end
end
