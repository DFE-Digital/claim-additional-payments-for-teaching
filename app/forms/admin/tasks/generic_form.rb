class Admin::Tasks::GenericForm
  PERMITTED_PARAMS = %w[name passed].freeze

  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :claim
  attribute :admin_user
  attribute :name, :string # aka task_name

  attribute :passed, :boolean

  validates :passed,
    inclusion: {
      in: [true, false],
      message: ->(form, _data) { form.passed_inclusion_error_message }
    }

  def self.permitted_params
    PERMITTED_PARAMS
  end

  def save
    return false if invalid?

    task.update(
      passed:,
      created_by: admin_user,
      manual: true
    )

    Event.create(claim:, name: "task_#{name}_#{passed}", actor: admin_user, entity: task)

    task
  end

  def radio_options
    [
      OpenStruct.new(id: true, name: "Yes"),
      OpenStruct.new(id: false, name: "No")
    ]
  end

  def claim_verifier_match
    task.claim_verifier_match
  end

  def translation
    "#{claim.policy.to_s.underscore}.admin.task_questions.#{task.name}"
  end

  def task
    @task ||= claim.tasks.where(name:).first || claim.tasks.build(name:)
  end

  def passed_inclusion_error_message
    "You must select ‘Yes’ or ‘No’"
  end
end
