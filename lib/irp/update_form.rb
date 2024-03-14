class UpdateForm
  def self.call(...)
    service = new(...)
    return service unless service.valid?

    service.update_form!
    service.capture_form_analytics
    service
  end

  def initialize(step, params)
    @step = step
    @form = step.form
    @params = params
  end
  attr_reader :step, :form, :params

  def valid?
    step.update(**parsed_params)
    step.valid?
  end

  def success?
    step.errors.blank?
  end

  def update_form!
    form.update(**parsed_params)
  end

  def capture_form_analytics
    # TODO: What's the claim way to do this?
    # changes = form.saved_changes
    # action = :updated
    # action = :created if changes.key?(:id)

    # Event.publish(action, form, changes) if changes.present?
  end

  private

  def parsed_params
    @parsed_params ||= ParsedParams.new(params).execute
  end
end
