# frozen_string_literal: true

class AdminSession < DfeSignIn::AuthenticatedSession
  SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_access"
  SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_support"

  def is_service_operator?
    role_codes.include?(SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
  end

  def is_support_agent?
    role_codes.include?(SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)
  end

  def has_admin_access?
    is_service_operator? || is_support_agent?
  end
end
