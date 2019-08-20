# frozen_string_literal: true

class AdminSession < DfeSignIn::AuthenticatedSession
  SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_access"

  def is_service_operator?
    role_codes.include?(SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
  end
end
