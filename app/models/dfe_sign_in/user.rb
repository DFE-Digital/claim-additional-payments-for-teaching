module DfeSignIn
  class User < ApplicationRecord
    USER_TYPES = %w[admin provider].freeze

    include Deletable

    SERVICE_OPERATOR_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_access"
    SERVICE_ADMIN_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_admin"
    SUPPORT_AGENT_DFE_SIGN_IN_ROLE_CODE = "teacher_payments_support"

    has_secure_token :session_token

    after_create :send_slack_notification

    scope :admin, -> { where(user_type: "admin") }
    scope :provider, -> { where(user_type: "provider") }

    def self.table_name
      "dfe_sign_in_users"
    end

    has_many :assigned_claims, class_name: "Claim",
      foreign_key: :assigned_to_id,
      inverse_of: :assigned_to,
      dependent: :nullify

    def self.from_session(session)
      user = where(dfe_sign_in_id: session.user_id, user_type: "admin").first_or_initialize

      return if user.deleted?

      user.role_codes = session.role_codes
      user
    end

    def self.client_id_for_user_type(user_type)
      case user_type
      when "admin"
        ENV.fetch("DFE_SIGN_IN_INTERNAL_CLIENT_ID")
      when "provider"
        ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID")
      else
        raise "client_id not found for user_type: #{user_type}"
      end
    end

    def self.user_type_for_client_id(client_id)
      case client_id
      when ENV.fetch("DFE_SIGN_IN_INTERNAL_CLIENT_ID")
        "admin"
      when ENV.fetch("DFE_SIGN_IN_API_CLIENT_ID")
        "provider"
      else
        raise "user_type not found for client_id: #{client_id}"
      end
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
      is_service_operator? || is_support_agent?
    end

    def self.options_for_select
      not_deleted
        .where(role_codes: ["teacher_payments_access"])
        .where(user_type: "admin")
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

    def client_id
      raise "use class method"
    end

    private

    def unassign_claims
      assigned_claims.update(assigned_to_id: nil)
    end

    def send_slack_notification
      SlackNotificationJob.perform_later(id) if ENV.fetch("ENVIRONMENT_NAME") == "production"
    end
  end
end
