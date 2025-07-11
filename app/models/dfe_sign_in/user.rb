module DfeSignIn
  class User < ApplicationRecord
    include Deletable

    SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_access"
    SERVICE_ADMIN_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_admin"
    SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_support"

    has_secure_token :session_token

    after_save :send_slack_notification

    def self.table_name
      "dfe_sign_in_users"
    end

    has_many :assigned_claims, class_name: "Claim",
      foreign_key: :assigned_to_id,
      inverse_of: :assigned_to,
      dependent: :nullify

    def self.from_session(session)
      user = where(dfe_sign_in_id: session.user_id).first_or_initialize

      return if user.deleted?

      user.role_codes = session.role_codes
      user.current_organisation_ukprn = session.organisation_ukprn
      user
    end

    def null_user?
      false
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

    def is_service_admin?
      role_codes.include?(SERVICE_ADMIN_DFE_SIGN_IN_ROLE_CODE)
    end

    def has_admin_access?
      is_service_operator? || is_support_agent? || is_service_admin?
    end

    def self.options_for_select
      not_deleted
        .where(role_codes: ["teacher_payments_access"])
        .order(email: :asc)
        .collect do |user|
        [
          user.full_name.titleize, user.id
        ]
      end
    end

    def mark_as_deleted!
      super
      unassign_claims
    end

    class Organisation < Struct.new(:ukprn, keyword_init: true); end

    def current_organisation
      @current_organisation ||= Organisation.new(
        ukprn: current_organisation_ukprn
      )
    end

    private

    def unassign_claims
      assigned_claims.update(assigned_to_id: nil)
    end

    def send_slack_notification
      SlackNotificationJob.perform_later(id) if granted_admin_access? && (ENV.fetch("ENVIRONMENT_NAME") == "production")
    end

    def granted_admin_access?
      return false unless saved_change_to_role_codes.present?

      new_roles = saved_change_to_role_codes.last - saved_change_to_role_codes.first
      (new_roles & [SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE, SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE, SERVICE_ADMIN_DFE_SIGN_IN_ROLE_CODE]).any?
    end
  end
end
