module EarlyCareerPayments
    class SchoolUpliftEligibility
      ELIGIBLE_LOCAL_AUTHORITY_DISTRICT_CODES = [
        "E08000016", # Barnsley
        "E06000009", # Blackpool
        "E06000036", # Bracknell Forest
        "E08000032", # Bradford
        "E08000026", # Coventry
        "E06000015", # Derby
        "E08000017", # Doncaster
        "E08000027", # Dudley
        "E06000011", # East Riding of Yorkshire
        "E06000006", # Halton
        "E06000046", # Isle of Wight
        "E06000010", # Kingston upon Hull, City of
        "E08000034", # Kirklees
        "E08000011", # Knowsle
        "E06000016", # Leicester
        "E08000012", # Liverpool
        "E06000032", # Luton
        "E06000002", # Middlesbrough
        "E06000042", # Milton Keynes
        "E06000013", # North Lincolnshire
        "E06000057", # Northumberland
        "E06000018", # Nottingham
        "E08000004", # Oldham
        "E06000031", # Peterborough
        "E06000044", # Portsmouth
        "E06000038", # Reading
        "E08000005", # Rochdale
        "E08000006", # Salford
        "E08000028", # Sandwell
        "E08000014", # Sefton
        "E08000019", # Sheffield
        "E08000013", # St.Helens
        "E06000021", # Stoke-on-Trent
        "E06000030", # Swindon
        "E08000008", # Tameside
        "E06000020", # Telford and Wrekin
        "E08000030", # Walsall
        "E06000007", # Warrington
        "E08000031", # Wolverhampton
      ].freeze
  
      def initialize(school)
        @school = school
      end
  
      def eligible_current_school?
        @school.open? &&
          eligible_local_authority_district? &&
          (@school.state_funded? || @school.secure_unit?) &&
          @school.secondary_or_equivalent?
      end
  
      private
  
      def eligible_local_authority_district?
        ELIGIBLE_LOCAL_AUTHORITY_DISTRICT_CODES.include?(@school.local_authority_district.code)
      end
    end
  end
  