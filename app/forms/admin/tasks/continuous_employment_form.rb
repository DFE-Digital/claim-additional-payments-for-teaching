class Admin::Tasks::ContinuousEmploymentForm
  PERMITTED_PARAMS = %w[name employment_breaks statutory].freeze

  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :claim
  attribute :admin_user
  attribute :name, :string # aka task_name

  attribute :employment_breaks, :boolean
  attribute :statutory, :boolean

  validates :employment_breaks,
    inclusion: {
      in: [true, false],
      message: "You must select ‘Yes’ or ‘No’"
    }

  validates :statutory,
    inclusion: {
      in: [true, false],
      message: "You must select ‘Yes’ or ‘No’"
    },
    if: proc { |form| form.employment_breaks }

  def self.permitted_params
    PERMITTED_PARAMS
  end

  def save
    return false if invalid?

    task.update(
      passed:,
      created_by: admin_user,
      manual: true,
      data:
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

  private

  def passed
    !employment_breaks || (employment_breaks && statutory)
  end

  def data
    {
      employment_breaks: employment_breaks,
      statutory: statutory
    }
  end
end
