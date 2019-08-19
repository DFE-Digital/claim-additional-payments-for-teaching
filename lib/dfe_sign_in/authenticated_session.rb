module DfeSignIn
  class AuthenticatedSession
    attr_reader :user_id, :organisation_id

    def initialize(user_id, organisation_id)
      @user_id = user_id
      @organisation_id = organisation_id
    end

    def self.from_auth_hash(auth_hash)
      user_id = auth_hash["uid"]
      organisation_id = auth_hash.dig("extra", "raw_info", "organisation", "id")
      new(user_id, organisation_id)
    end
  end
end
