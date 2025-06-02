class Admin::Tasks::GenericForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :claim
  attribute :admin_user
  attribute :name, :string # aka task_name

  attribute :passed, :boolean

  validates :passed,
    inclusion: {
      in: [true, false],
      message: "You must select ‘Yes’ or ‘No’"
    }

  def save
    return false if invalid?

    task.update(
      passed:,
      created_by: admin_user,
      manual: true
    )
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
end
