module DfeSignIn
  class AuthenticatedSession
    attr_reader :user_id, :organisation_id, :organisation_ukprn, :role_codes

    def initialize(user_id:, organisation_id:, organisation_ukprn:, role_codes:)
      @user_id = user_id
      @organisation_id = organisation_id
      @organisation_ukprn = organisation_ukprn
      @role_codes = role_codes
    end

    def self.from_auth_hash(auth_hash)
      user_id = auth_hash["uid"]
      organisation_hash = auth_hash.dig("extra", "raw_info", "organisation")
      organisation_id = organisation_hash.dig("id")
      organisation_ukprn = organisation_hash.dig("ukprn")
      role_codes = DfeSignIn::Api::User.new(user_id: user_id, organisation_id: organisation_id).role_codes

      new(user_id:, organisation_id:, organisation_ukprn:, role_codes:)
    end
  end
end
