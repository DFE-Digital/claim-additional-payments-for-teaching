class ServiceOperatorPolicy
  attr_reader :admin

  def initialize(admin, _record)
    @admin = admin
  end

  def method_missing(m, *args, &block)
    service_operator?
  end

  private

  def service_operator?
    admin.has_role?(:service_operator)
  end
end
