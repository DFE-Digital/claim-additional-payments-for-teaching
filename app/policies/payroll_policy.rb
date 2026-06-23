class PayrollPolicy
  attr_reader :admin

  def initialize(admin, object = nil)
    @admin = admin
  end

  def index?
    read?
  end

  def new?
    read?
  end

  def create?
    write?
  end

  def show?
    read?
  end

  def destroy?
    write?
  end

  def read?
    admin.roles.include?("payroll")
  end

  def write?
    admin.roles.include?("payroll")
  end
end
