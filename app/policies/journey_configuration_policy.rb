class JourneyConfigurationPolicy < ServiceAdminPolicy
  def index?
    service_operator? || admin?
  end

  private

  def service_operator?
    admin.has_role?(:service_operator)
  end
end
