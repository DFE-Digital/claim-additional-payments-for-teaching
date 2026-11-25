module Admin
  module Permissions
    # Declares which permission each controller action needs, e.g.
    #
    #   permissions show: "service_access_links.show",
    #     create: "service_access_links.create"
    #
    # Only enforced while the :admin_permissions feature flag is on. Actions
    # without a declared permission are not checked yet.
    module Enforcement
      extend ActiveSupport::Concern

      included do
        class_attribute :action_permissions, instance_writer: false, default: {}.freeze

        before_action :ensure_permitted, if: :admin_permissions_enabled?
      end

      class_methods do
        def permissions(action_permission_map)
          self.action_permissions = action_permissions
            .merge(action_permission_map.transform_keys(&:to_s))
            .freeze
        end
      end

      private

      def admin_permissions_enabled?
        FeatureFlag.enabled?(:admin_permissions)
      end

      def ensure_permitted
        permission = action_permissions[action_name]

        return if permission.nil?
        return if current_admin.permitted?(permission)

        render "admin/auth/failure", status: :forbidden
      end
    end
  end
end
