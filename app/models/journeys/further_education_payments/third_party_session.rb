module Journeys
  module FurtherEducationPayments
    class ThirdPartySession
      def self.session_key
        "further_education_payments_third_party_session"
      end

      def self.from_omniauth(auth_hash)
        new(
          organisation_id: auth_hash.extra.raw_info.organisation.id,
          organisation_ukprn: auth_hash.extra.raw_info.organisation.ukprn,
          uid: auth_hash.uid
        )
      end

      def self.from_session(hash)
        new(
          organisation_id: hash["organisation_id"],
          organisation_ukprn: hash["organisation_ukprn"],
          uid: hash["uid"]
        )
      end

      attr_reader :organisation_id, :organisation_ukprn, :uid

      def initialize(organisation_id:, organisation_ukprn:, uid:)
        @organisation_id = organisation_id
        @organisation_ukprn = organisation_ukprn
        @uid = uid
      end

      def to_h
        {
          organisation_id: organisation_id,
          organisation_ukprn: organisation_ukprn,
          uid: uid
        }
      end

      def signed_in?
        uid.present?
      end
    end
  end
end
