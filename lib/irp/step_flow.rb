class StepFlow
  # rubocop:disable Layout/HashAlignment
  STEPS = {
    ApplicationRouteStep::ROUTE_KEY => ApplicationRouteStep,
    TraineeDetailsStep::ROUTE_KEY => TraineeDetailsStep,
    SchoolDetailsStep::ROUTE_KEY => SchoolDetailsStep,
    ContractDetailsStep::ROUTE_KEY => ContractDetailsStep,
    StartDateStep::ROUTE_KEY => StartDateStep,
    SubjectStep::ROUTE_KEY => SubjectStep,
    VisaStep::ROUTE_KEY => VisaStep,
    EntryDateStep::ROUTE_KEY => EntryDateStep,
    PersonalDetailsStep::ROUTE_KEY => PersonalDetailsStep,
    EmploymentDetailsStep::ROUTE_KEY => EmploymentDetailsStep,
  }.freeze
  # rubocop:enable Layout/HashAlignment

  class << self
    include Rails.application.routes.url_helpers

    def teacher_steps
      STEPS.values - [TraineeDetailsStep]
    end

    def trainee_steps
      STEPS.values - [ContractDetailsStep, SchoolDetailsStep]
    end

    def matches?(request)
      STEPS.key?(request.params[:name])
    end

    def current_step(form, requested_step_name)
      return if form.blank? && requested_step_name != ApplicationRouteStep::ROUTE_KEY
      return ApplicationRouteStep.new(Form.new) unless form

      STEPS.fetch(requested_step_name).new(form)
    end

    def next_step_path(step)
      unless step.form.eligible?
        return irp_ineligible_salaried_course_path if step.form.trainee_route?

        return irp_ineligible_path
      end

      return irp_summary_path if step.is_a?(EmploymentDetailsStep)
      return EmploymentDetailsStep.path if step.is_a?(PersonalDetailsStep)
      return PersonalDetailsStep.path if step.is_a?(EntryDateStep)
      return EntryDateStep.path if step.is_a?(VisaStep)
      return VisaStep.path if step.is_a?(SubjectStep)
      return SubjectStep.path if step.is_a?(StartDateStep)
      return StartDateStep.path if step.is_a?(ContractDetailsStep)
      return ContractDetailsStep.path if step.is_a?(SchoolDetailsStep)
      return StartDateStep.path if step.is_a?(TraineeDetailsStep)
      return TraineeDetailsStep.path if step.is_a?(ApplicationRouteStep) && step.form.trainee_route?
      return SchoolDetailsStep.path if step.is_a?(ApplicationRouteStep) && step.form.teacher_route?
    end

    def previous_step_path(step)
      return PersonalDetailsStep.path if step.is_a?(EmploymentDetailsStep)
      return EntryDateStep.path if step.is_a?(PersonalDetailsStep)
      return VisaStep.path if step.is_a?(EntryDateStep)
      return SubjectStep.path if step.is_a?(VisaStep)
      return StartDateStep.path if step.is_a?(SubjectStep)
      return TraineeDetailsStep.path if step.is_a?(StartDateStep) && step.form.trainee_route?
      return ContractDetailsStep.path if step.is_a?(StartDateStep) && step.form.teacher_route?
      return SchoolDetailsStep.path if step.is_a?(ContractDetailsStep)
      return ApplicationRouteStep.path if step.is_a?(TraineeDetailsStep)
      return ApplicationRouteStep.path if step.is_a?(SchoolDetailsStep)
    end
  end
end
