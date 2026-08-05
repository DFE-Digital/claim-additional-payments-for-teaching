class ServiceAdminPolicy
  attr_reader :admin

  def initialize(admin, _record)
    @admin = admin
  end

  def method_missing(m, *args, &block)
    admin?
  end

  private

  def admin?
    admin.has_role?(:service_admin)
  end
end
