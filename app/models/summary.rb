class Summary
  include ActiveModel::Model
  include ActionView::Helpers::TranslationHelper

  def initialize(form)
    @form = form
    @personal_details_step = PersonalDetailsStep.new(form)
    @employment_details_step = EmploymentDetailsStep.new(form)
  end
  attr_reader :form

  delegate :errors, to: :form

  def rows
    single_field_steps.map(&method(:format_single_row))
  end

  def personal_card
    link = yield("Change", personal_details_step.path)
    {
      title: personal_details_step.question,
      actions: [link],
    }
  end

  def personal_rows
    personal_details_answers.map(&method(:format_answer))
  end

  def employment_card
    link = yield("Change", employment_details_step.path)
    {
      title: employment_details_step.question,
      actions: [link],
    }
  end

  def employment_rows
    employment_details_answers.map(&method(:format_answer))
  end

private

  attr_reader :personal_details_step, :employment_details_step

  def reorder(answers, field_name, after:)
    field_index = answers.index { _1.field_name == field_name }
    field = answers.delete_at(field_index)
    after_index = answers.index { _1.field_name == after }

    answers.insert(after_index + 1, field)
    answers
  end

  def personal_details_answers
    a = reorder(personal_details_step.answers, :middle_name, after: :family_name)
    reorder(a, :address_line_2, after: :address_line_1)
  end

  def employment_details_answers
    reorder(employment_details_step.answers, :school_address_line_2, after: :school_address_line_1)
  end

  def single_field_steps
    application_route_steps - [PersonalDetailsStep, EmploymentDetailsStep]
  end

  def application_route_steps
    return StepFlow.teacher_steps if form.teacher_route?

    StepFlow.trainee_steps
  end

  def format_answer(answer)
    {
      key: { text: t("summary.#{answer.field_name}") },
      value: { text: answer.formatted_value },
    }
  end

  def format_single_row(step_class)
    step = step_class.new(form)
    {
      key: { text: t("summary.#{step.answer.field_name}") },
      value: { text: step.answer&.formatted_value },
      actions: [
        {
          href: step.path,
          visually_hidden_text: step.class::ROUTE_KEY.tr("-", " "),
        },
      ],
    }
  end
end
