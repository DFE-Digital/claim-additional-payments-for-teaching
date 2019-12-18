module DfeSignIn
  class User < ApplicationRecord
    def self.table_name
      "dfe_sign_in_users"
    end
  end
end
