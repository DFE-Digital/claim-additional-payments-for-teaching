module Policies
  module StudentLoans
    module Test
      class SchoolImporter
        def self.import!
          new.import!
        end

        def import!
          ActiveRecord::Base.transaction do
            school_names.each_with_index do |name, index|
              urn = 989999 - index

              local_authority = if name.match?(/ineligible/i)
                ineligible_local_authority
              else
                eligible_local_authority
              end

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

        def eligible_local_authority
          @eligible_local_authority ||= LocalAuthority
            .find_or_create_by!(
              name: "Barnsley",
              code: 370
            )
        end

        def ineligible_local_authority
          @ineligible_local_authority ||= LocalAuthority
            .find_or_create_by!(
              name: "Rochdale",
              code: 354
            )
        end

        def local_authority_district
          @local_authority_district ||= LocalAuthorityDistrict
            .find_or_create_by!(
              name: "Claim testing"
            )
        end
      end
    end
  end
end
