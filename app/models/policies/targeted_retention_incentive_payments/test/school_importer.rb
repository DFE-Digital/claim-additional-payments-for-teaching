module Policies
  module TargetedRetentionIncentivePayments
    module Test
      class SchoolImporter
        def self.run
          new.import!
        end

        def import!
          ActiveRecord::Base.transaction do
            school_names.each_with_index do |name, index|
              urn = 999999 - index

              School.find_or_create_by!(
                name:,
                urn:,
                school_type: :community_school,
                school_type_group: :la_maintained,
                phase: :secondary,
                local_authority:,
                local_authority_district:
              )
            end
          end
        end

        private

        def school_names
          UserPersona.all.map(&:school_name).uniq
        end

        def local_authority
          @local_authority ||= LocalAuthority.find_or_create_by!(name: "STRI Test")
        end

        def local_authority_district
          @local_authority_district ||= LocalAuthorityDistrict.find_or_create_by!(name: "Claim testing")
        end
      end
    end
  end
end
