class Admin::Tasks::PayrollGenderForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :claim
  attribute :admin_user
  attribute :name, :string # aka task_name

  attribute :payroll_gender, :string

  validates :payroll_gender,
    inclusion: {
      in: %w[female male],
      message: "You must select a gender that will be passed to HMRC"
    }

  def save
    return false if invalid?

    begin
      ActiveRecord::Base.transaction do
        task.passed = true
        task.manual = true
        task.created_by = admin_user
        task.save!

        claim.payroll_gender = payroll_gender
        claim.save!(context: :"payroll-gender-task")
      end
    rescue ActiveRecord::RecordInvalid
      false
    end
  end

  def radio_options
    [
      OpenStruct.new(id: "female", name: "Female"),
      OpenStruct.new(id: "male", name: "Male")
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
