module Admin
  module Permissions
    ALL = %w[
      service_access_links.show
      service_access_links.create
    ].freeze

    def self.table_name_prefix
      "admin_permissions_"
    end
  end
end
