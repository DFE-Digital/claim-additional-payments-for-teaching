class ServiceOperatorPolicy
  attr_reader :admin

  def initialize(admin, _record)
    @admin = admin
  end

  def method_missing(m, *args, &block)
    service_operator?
  end

  def respond_to_missing?(method_name, include_private = false)
    method_name.to_s.ends_with?("?") || super
  end

  private

  def service_operator?
    admin.has_role?(:service_operator)
  end
end
