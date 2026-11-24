module Admin
  module Permissions
    class Grant < ApplicationRecord
      belongs_to :user, class_name: "DfeSignIn::User"
      belongs_to :granted_by, class_name: "DfeSignIn::User", optional: true
      belongs_to :revoked_by, class_name: "DfeSignIn::User", optional: true

      scope :active, -> { where(revoked_at: nil) }

      validates :permission, inclusion: {in: ALL}
      validates :granted_at, presence: true
      validate :user_is_admin

      private

      def user_is_admin
        return if user.nil? || user.user_type == "admin"

        errors.add(:user, "must be an admin user")
      end
    end
  end
end
