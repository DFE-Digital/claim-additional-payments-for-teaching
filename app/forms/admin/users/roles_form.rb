class Admin::Users::RolesForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :user
  attribute :roles

  validates :roles,
    inclusion: {
      in: ->(form) { form.checkbox_options.map(&:id) + [""] },
      message: "Select a valid role"
    }

  def checkbox_options
    [
      Form::Option.new(
        id: "product",
        name: "Product",
        hint: "Read-only view of the application. Typically assigned to users part of the product team"
      ),
      Form::Option.new(
        id: "support",
        name: "Support agent",
        hint: "Write access to claims. Typically assigned to users part of the OPs team"
      ),
      Form::Option.new(
        id: "privileged_support",
        name: "Privileged support agent",
        hint: "Grants additional permissions to more sensitive actions, such as modify bank details"
      ),
      Form::Option.new(
        id: "payroll",
        name: "Payroll",
        hint: "Able to manage payroll"
      ),
      Form::Option.new(
        id: "admin",
        name: "Admin",
        hint: "Grants higher level permissions such as manage users and services"
      )
    ]
  end

  def save
    return if invalid?

    user.update(roles: roles.reject(&:blank?))
  end
end
