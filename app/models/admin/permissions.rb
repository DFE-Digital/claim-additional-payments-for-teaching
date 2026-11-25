module Admin
  module Permissions
    ALL = %w[
      admin.read
      payroll.write
      payroll_confirmation.write
      service_access_links.write
    ].freeze

    def self.table_name_prefix
      "admin_permissions_"
    end
  end
end
