module DfeSignIn
  class User < ApplicationRecord
    def self.table_name
      "dfe_sign_in_users"
    end

    def full_name
      [given_name, family_name].join(" ")
    end
  end
end
