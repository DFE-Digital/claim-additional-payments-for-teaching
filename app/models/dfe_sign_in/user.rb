module DfeSignIn
  class User < ApplicationRecord
    SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_access"
    SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_support"
    PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_payroll"

    def self.table_name
      "dfe_sign_in_users"
    end

    def full_name
      [given_name, family_name].join(" ")
    end

    def is_service_operator?
      role_codes.include?(SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
    end

    def is_support_agent?
      role_codes.include?(SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE)
    end

    def is_payroll_operator?
      role_codes.include?(PAYROLL_OPERATOR_DFE_SIGN_IN_ROLE_CODE)
    end

    def has_admin_access?
      is_service_operator? || is_support_agent? || is_payroll_operator?
    end
  end
end
